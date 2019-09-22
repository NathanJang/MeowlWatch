//
//  MeowlWatchData.swift
//  MeowlWatchData
//
//  Created by Jonathan Chan on 2017-03-17.
//  Copyright © 2018 Jonathan Chan. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper
import Alamofire
import Kanna

/// The constant group name for shared defaults and keychain.
private let accessGroupName = "group.me.jonathanchan.MeowlWatch"

/// The shared user defaults object.
private let userDefaults = UserDefaults(suiteName: accessGroupName)!

/// The shared keychain wrapper object.
private let keychain = KeychainWrapper(serviceName: "me.jonathanchan.MeowlWatch", accessGroup: accessGroupName)

/// Configures the MeowlWatchData initially by reading from (and writing to, if necessary) user defaults and the keychain.
public func loadFromDefaults() {
    if let data = userDefaults.object(forKey: "lastQuery") as? Data {
        lastQuery = NSKeyedUnarchiver.unarchiveObject(with: data) as? QueryResult
        netID = keychain.string(forKey: "netID")
        password = keychain.string(forKey: "password")
    } else if !userDefaults.bool(forKey: "didFinishFirstLaunch") {
        // This is the first launch
        _ = keychain.removeAllKeys()
    }

    if let intArray = userDefaults.object(forKey: "widgetArrangement") as? [Int], intArray.count == widgetArrangement.count {
        let storedWidgetArrangement = intArray.compactMap { return QueryResult.WidgetDisplayItem(rawValue: $0) }
        if storedWidgetArrangement.count == widgetArrangement.count {
            widgetArrangement = storedWidgetArrangement
        }
    }

    if let existingArray = userDefaults.array(forKey: "hiddenSections") as? [Int] {
        hiddenSections = existingArray
    }

    if let storedWidgetIsPurchased = keychain.bool(forKey: "widgetPurchased") {
        widgetIsPurchased = storedWidgetIsPurchased
    } else {
        widgetIsPurchased = userDefaults.bool(forKey: "widgetPurchased")
        userDefaults.removeObject(forKey: "widgetPurchased")
    }

    if let storedCurrentLanguageId = userDefaults.string(forKey: "currentLanguageId"), let storedCurrentLanguage = Language(rawValue: storedCurrentLanguageId) {
        currentLanguage = storedCurrentLanguage
        selectedLanguage = currentLanguage
    }

    appVersion = userDefaults.string(forKey: "appVersion")
}

/// Writes data from the MeowlWatchData to user defaults.
public func persistToUserDefaults() {
    userDefaults.set(true, forKey: "didFinishFirstLaunch")

    if let lastQuery = lastQuery {
        let data = NSKeyedArchiver.archivedData(withRootObject: lastQuery)
        userDefaults.set(data, forKey: "lastQuery")
    }

    let intArray = widgetArrangement.compactMap { return $0.rawValue }
    userDefaults.set(intArray, forKey: "widgetArrangement")

    userDefaults.set(hiddenSections, forKey: "hiddenSections")

    keychain.set(widgetIsPurchased, forKey: "widgetPurchased", withAccessibility: .always)

    if selectedLanguage == .default {
        userDefaults.removeObject(forKey: "currentLanguageId")
    } else {
        userDefaults.set(selectedLanguage.rawValue, forKey: "currentLanguageId")
    }

    userDefaults.set(appVersion, forKey: "appVersion")
}

public var appVersion: String?

/// A boolean representing whether we're prepared to query the server.
public var canQuery: Bool { return netID != nil && !netID!.isEmpty && password != nil }

/// The user's NetID.
public private(set) var netID: String?

/// The user's password.
/// This should be stored securely and handled with care.
public private(set) var password: String?

/// Sets the NetID and password variables, and persists it across sessions to the keychain.
/// - Parameter netID: The user's NetID.
/// - Parameter password: The user's password.
/// - Returns: Whether the result was successful.
@discardableResult
public func updateCredentials(netID aNetID: String?, password aPassword: String?) -> Bool {
    var success = true
    if aNetID == nil || aNetID!.isEmpty || aPassword == nil {
        netID = nil
        password = nil

        success = keychain.removeObject(forKey: "netID") && success
        success = keychain.removeObject(forKey: "password") && success
    } else if let aNetID = aNetID, let aPassword = aPassword {
        netID = aNetID
        password = aPassword

        success = keychain.set(aNetID, forKey: "netID", withAccessibility: .afterFirstUnlock) && success
        success = keychain.set(aPassword, forKey: "password", withAccessibility: .afterFirstUnlock) && success
    }

    return success
}

private let sessionManager: Alamofire.SessionManager = { () -> Alamofire.SessionManager in
    let configuration = URLSessionConfiguration.default
    return Alamofire.SessionManager(configuration: configuration)
}()

private func finishWithParseError(onCompletion: ((_ result: QueryResult) -> Void)) {
    finishQuery(result: QueryResult(lastQuery: lastQuery, error: .parseError), onCompletion: onCompletion)
}

/// Queries the server and calls the completion handler with a query result.
/// - Parameter onCompletion: The completion handler.
public func query(onCompletion: (@escaping (_ result: QueryResult) -> Void)) {
    print("Query requested")

    guard canQuery, let netID = netID, let password = password else {
        print("No credentials provided")
        return finishQuery(result: QueryResult(lastQuery: lastQuery, error: .authenticationError), onCompletion: onCompletion)
    }

    var urlString = "https://websso.it.northwestern.edu/amserver/cdcservlet?goto=https://form.housing.northwestern.edu:443/foodservice/public/balancecheckplain.aspx&RequestID=14358&MajorVersion=1&MinorVersion=0&ProviderID=https://form.housing.northwestern.edu:443/amagent&IssueInstant="
    urlString.append({ () -> String in
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = diningCalendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH'%3A'mm'%3A'ss'Z'"
        return dateFormatter.string(from: Date())
    }())

    print("Pinging \(urlString)")
    sessionManager.request(urlString).responseString { response in
        guard response.error == nil && response.response != nil, let htmlString = response.value else {
            print("Query connection error")
            return finishQuery(result: QueryResult(lastQuery: lastQuery, error: .connectionError), onCompletion: onCompletion)
        }

        guard let html = try? HTML(html: htmlString, encoding: .utf8) else {
            print("Invalid html tree")
            return finishWithParseError(onCompletion: onCompletion)
        }
        var gotoParamValue: String
        let gotoOnFailParamValue: String
        var sunQueryParamsStringParamValue: String
        let encodedParamValue: String
        let gxCharsetParamValue: String
        guard let gotoParamEl = html.at_css("input[name=\"goto\"]"), gotoParamEl["value"] != nil else {
            print("Could not parse `goto`")
            return finishWithParseError(onCompletion: onCompletion)
        }
        gotoParamValue = gotoParamEl["value"]!

        guard let gotoOnFailEl = html.at_css("input[name=\"gotoOnFail\"]"), gotoOnFailEl["value"] != nil else {
            print("Could not parse `gotoOnFail`")
            return finishWithParseError(onCompletion: onCompletion)
        }
        gotoOnFailParamValue = gotoOnFailEl["value"]!

        guard let sunQueryParamsStringEl = html.at_css("input[name=\"SunQueryParamsString\"]"), sunQueryParamsStringEl["value"] != nil else {
            print("Could not parse `SunQueryParamsString`")
            return finishWithParseError(onCompletion: onCompletion)
        }
        sunQueryParamsStringParamValue = sunQueryParamsStringEl["value"]!

        guard let encodedEl = html.at_css("input[name=\"encoded\"]"), encodedEl["value"] != nil else {
            print("Could not parse `encoded`")
            return finishWithParseError(onCompletion: onCompletion)
        }
        encodedParamValue = encodedEl["value"]!

        guard let gxCharsetEl = html.at_css("input[name=\"gx_charset\"]"), gxCharsetEl["value"] != nil else {
            print("Could not parse `gx_charset`")
            return finishWithParseError(onCompletion: onCompletion)
        }
        gxCharsetParamValue = gxCharsetEl["value"]!
        let parameters = [
            "goto" : gotoParamValue,
            "gotoOnFail" : gotoOnFailParamValue,
            "SunQueryParamsString" : sunQueryParamsStringParamValue,
            "encoded" : encodedParamValue,
            "gx_charset" : gxCharsetParamValue,
            "IDButton" : "Log+In",
            "IDToken1" : netID,
            "IDToken2" : password
        ]
        let loginUrlString = "https://websso.it.northwestern.edu/amserver/UI/Login"
        print("Pinging \(loginUrlString)")
        debugPrint("Pinging \(loginUrlString) with parameters \(parameters)")
        let request = sessionManager.request(loginUrlString, method: .post, parameters: parameters, encoding: URLEncoding(destination: .httpBody))
        request.responseString { response in
            guard response.error == nil && response.response != nil, let html = response.value else {
                print("Request to \(loginUrlString) failed to connect")
                return finishQuery(result: QueryResult(lastQuery: lastQuery, error: .connectionError), onCompletion: onCompletion)
            }

            parseLaresParamValueDuringQueryAndRedirect(html: html, previousNumberOfRedirects: 0, onCompletion: onCompletion)
        }
    }
}

/// Sometimes when we ping https://form.housing.northwestern.edu/foodservice/public/balancecheckplain.aspx, the html is the same as the previous LARES html thing, but with a different LARES value. I'm assuming we need to re-ping the same site with the updated value, so this recursively does that.
fileprivate func parseLaresParamValueDuringQueryAndRedirect(html: String, previousNumberOfRedirects: Int, onCompletion: (@escaping (_ result: QueryResult) -> Void)) {
    guard previousNumberOfRedirects < 5 else {
        print("Too many redirects in recursive LARES parse")
        return finishWithParseError(onCompletion: onCompletion)
    }
    let laresMatchRegexPattern = "<input type=\"hidden\" name=\"LARES\" value=\"([a-zA-Z0-9+=]*)\""

    let laresParamValue: String
    do {
        guard let value = try html.firstMatch(regexPattern: laresMatchRegexPattern).first else {
            if try !html.firstMatch(regexPattern: "The NetID and/or password you entered was invalid.").isEmpty {
                print("Failed to authenticate with given credentials")
                return finishQuery(result: QueryResult(lastQuery: lastQuery, error: .authenticationError), onCompletion: onCompletion)
            }
            print("Could not parse `LARES`")
            return finishWithParseError(onCompletion: onCompletion)
        }
        laresParamValue = value
    } catch {
        print("Regex parsing threw in LARES parse")
        return finishWithParseError(onCompletion: onCompletion)
    }
    let balanceCheckUrlString = "https://form.housing.northwestern.edu/foodservice/public/balancecheckplain.aspx"
    let parameters = ["LARES" : laresParamValue]
    print("Pinging \(balanceCheckUrlString)")
    debugPrint("Pinging \(balanceCheckUrlString) with parameters \(parameters)")
    let request = sessionManager.request(balanceCheckUrlString, method: .post, parameters: parameters, encoding: URLEncoding(destination: .httpBody))
    request.responseString { response in
        do {
            guard let html = response.value else {
                print("Balance check page HTML result unknown")
                return finishWithParseError(onCompletion: onCompletion)
            }
            guard try html.firstMatch(regexPattern: laresMatchRegexPattern).count == 0 else {
                print("Recursing LARES parsing")
                return parseLaresParamValueDuringQueryAndRedirect(html: html, previousNumberOfRedirects: previousNumberOfRedirects + 1, onCompletion: onCompletion)
            }
            guard let queryResult = QueryResult(htmlString: html) else {
                print("Could not parse balance check html")
                return finishWithParseError(onCompletion: onCompletion)
            }
            print("Query successful")
            return finishQuery(result: queryResult, onCompletion: onCompletion)
        } catch {
            print("Regex parsing threw")
            return finishWithParseError(onCompletion: onCompletion)
        }
    }
}

/// What to do when query is finished.
/// - Parameter result: The query result.
/// - Parameter onCompletion: The callback for when the query completes.
private func finishQuery(result: QueryResult, onCompletion: ((_ result: QueryResult) -> Void)) {
    lastQuery = result
    guard let storage = sessionManager.session.configuration.httpCookieStorage, let cookies = storage.cookies else { return onCompletion(result) }
    for cookie in cookies {
        storage.deleteCookie(cookie)
    }
    return onCompletion(result)
}

/// The result of the last query to the server.
public var lastQuery: QueryResult?

/// The sections on the main VC that are hidden.
/// Initialized to a default value.
public var hiddenSections: [Int] = [3, 4, 5]

/// The time interval before we should refresh from the server.
private let refreshThreshold: TimeInterval = 60 * 30

private let errorRefreshThreshold: TimeInterval = 60 * 5

/// Whether we should refresh.
public var shouldRefresh: Bool {
    guard canQuery else { return false }
    guard let lastQuery = lastQuery else { return true }
    let intervalSinceLastUpdated = Date().timeIntervalSince(lastQuery.dateUpdated)
    if lastQuery.error != nil {
        return intervalSinceLastUpdated > errorRefreshThreshold
    } else {
        return intervalSinceLastUpdated > refreshThreshold
    }
}

/// The date formatter for displaying dates to the user.
/// Not to be confused with the date formatter used when parsing the HTML.
var displayDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .short
    dateFormatter.timeStyle = .short
    return dateFormatter
}()

/// Reads from the AdMobKeys property list files depending on compile-time configuration.
/// The `AdMobKeys-Release.plist` file should be configured similarly to `AdMobKeys-Debug.plist`.
/// - Parameter key: The key in the `plist` file.
/// - Returns: The object stored in the `plist` file for the give key.
private func adMobObject(forKey key: String) -> Any? {
    let path: String
    #if DEBUG
        path = Bundle.main.path(forResource: "AdMobKeys-Debug", ofType: "plist")!
    #else
        path = Bundle.main.path(forResource: "AdMobKeys-Release", ofType: "plist")!
    #endif

    return NSDictionary(contentsOfFile: path)!.value(forKey: key)
}

// MARK: AdMob

/// The banner ad unit ID for AdMob.
public var adMobBannerAdUnitID: String {
    return adMobObject(forKey: "AdMobBannerAdUnitID") as! String
}

/// The interstitial ad unit ID for AdMob.
public var adMobInterstitialAdUnitID: String {
    return adMobObject(forKey: "AdMobInterstitialAdUnitID") as! String
}

// MARK: Widget

/// An array representing the user's arrangement of the widget items.
/// The default is shown here, and then modified once user defaults are loaded.
public private(set) var widgetArrangement: [QueryResult.WidgetDisplayItem] = [.points, .mealExchanges, .boardMeals, .catCash]

/// Rearranges the widget arrangement preferences given indices in `widgetArrangement`.
/// - Parameter fromIndex: The index from which the item originated.
/// - Parameter toIndex: The index to which the item should be moved.
public func moveWidgetArrangement(fromIndex: Int, toIndex: Int) {
    let item = widgetArrangement.remove(at: fromIndex)
    widgetArrangement.insert(item, at: toIndex)
}

// MARK: IAPs

/// The product identifier for the IAP for the widget.
public let widgetProductIdentifier = "me.jonathanchan.MeowlWatch.MeowlWatch_Widget"

/// Whether the user purchased the widget.
public var widgetIsPurchased = false

/// Whether anything is purchased.
public var anythingIsPurchased: Bool { return widgetIsPurchased }

/// Whether we should display ads.
public var shouldDisplayAds: Bool { return !anythingIsPurchased }

public var rateOnAppStoreUrl: String {
    let appId = 1219875692
    return "itms-apps://itunes.apple.com/app/viewContentsUserReviews?id=\(appId)&action=write-review"
}

public var githubUrl: String {
    return "https://github.com/NathanJang/MeowlWatch"
}

// MARK: - Localization

/// Supported languages.
public enum Language: String {
    case `default`
    case english = "en"
    case chineseSimplified = "zh-Hans"
    case chineseTraditional = "zh-Hant"
    case french = "fr"
}

public let languages = [Language.default, .english, .chineseSimplified, .chineseTraditional, .french]

public var selectedLanguage = Language.default

public var currentLanguage = Language.default

public var currentLocalizedBundle: Bundle {
    let bundle: Bundle
    if currentLanguage == .default {
        bundle = .main
    } else {
        let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj")!
        bundle = Bundle(path: path)!
    }
    return bundle
}

public func mwLocalizedString(_ key: String, comment: String = "") -> String {
    return NSLocalizedString(key, bundle: currentLocalizedBundle, comment: comment)
}

public func systemDefaultLanguage() -> Language {
    func dropLastComponent(id: String) -> String { return id.split(separator: "-" ).dropLast().joined(separator: "-") }
    let firstAvailableLocaleId = Locale.preferredLanguages.map { dropLastComponent(id: $0) }.filter { languages.map { $0.rawValue }.contains($0) }.first ?? "en"
    return Language(rawValue: firstAvailableLocaleId) ?? .english
}
