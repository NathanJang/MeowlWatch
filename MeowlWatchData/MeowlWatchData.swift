//
//  MeowlWatchData.swift
//  MeowlWatchData
//
//  Created by Jonathan Chan on 2017-03-17.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper
import Alamofire

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
    } else {
        // This is the first launch
        let _ = keychain.removeAllKeys()
    }

    if let intArray = userDefaults.object(forKey: "widgetArrangement") as? [Int], intArray.count == widgetArrangement.count {
        widgetArrangement = intArray.flatMap { return QueryResult.WidgetDisplayItem(rawValue: $0)! }
    }

    widgetIsPurchased = userDefaults.bool(forKey: "widgetPurchased")
}

/// Writes data from the MeowlWatchData to user defaults.
public func persistToUserDefaults() {
    if let lastQuery = lastQuery {
        let data = NSKeyedArchiver.archivedData(withRootObject: lastQuery)
        userDefaults.set(data, forKey: "lastQuery")
    }

    let intArray = widgetArrangement.flatMap { return $0.rawValue }
    userDefaults.set(intArray, forKey: "widgetArrangement")

    userDefaults.set(widgetIsPurchased, forKey: "widgetPurchased")

    if userDefaults.responds(to: #selector(UserDefaults.synchronize)) { userDefaults.synchronize() }
}

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
    } else {
        netID = aNetID!
        password = aPassword!

        success = keychain.set(netID!, forKey: "netID") && success
        success = keychain.set(password!, forKey: "password") && success
    }

    return success
}

/// The URL object to query at.
/// Since this server only supports TLSv1.0, an appropriate exception should be made in `Info.plist`.
private let url: URL = URL(string: "https://go.dosa.northwestern.edu/uhfs/foodservice/balancecheck")!

private let sessionManager: Alamofire.SessionManager = { () -> Alamofire.SessionManager in
//    var headers = Alamofire.SessionManager.defaultHTTPHeaders
//    headers["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_4) AppleWebKit/603.1.30 (KHTML, like Gecko) Version/10.1 Safari/603.1.30"
//    headers["Referer"] = "https://websso.it.northwestern.edu/amserver/cdcservlet?goto=https%3A%2F%2Fform.housing.northwestern.edu%3A443%2Ffoodservice%2Fpublic%2Fbalancecheckplain.aspx&RequestID=7502&MajorVersion=1&MinorVersion=0&ProviderID=https%3A%2F%2Fform.housing.northwestern.edu%3A443%2Famagent&IssueInstant=2017-05-01T20%3A39%3A00Z"
//    headers["Host"] = "websso.it.northwestern.edu"
//    headers["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
//    headers["Connection"] = "keep-alive"
//    headers["Upgrade-Insecure-Requests"] = "1"
    let configuration = URLSessionConfiguration.default
//    configuration.httpAdditionalHeaders = headers
    return Alamofire.SessionManager(configuration: configuration)
}()

/// Queries the server and calls the completion handler with a query result.
/// - Parameter onCompletion: The completion handler.
public func query(onCompletion: (@escaping (_ result: QueryResult) -> Void)) {
    print("Querying...")
//    guard canQuery else {
//        return finishQuery(result: QueryResult(lastQuery: lastQuery, error: .authenticationError), onCompletion: onCompletion)
//    }
//
//    let credentialsString = "\(netID!):\(password!)"
//    let credentialsData = credentialsString.data(using: .utf8)!
//    let credentialsEncodedBase64 = credentialsData.base64EncodedString()
//    let authorizationString = "Basic \(credentialsEncodedBase64)"
//    var request = URLRequest(url: url)
//    request.setValue(authorizationString, forHTTPHeaderField: "Authorization")
//
//    let task = URLSession.shared.dataTask(with: request) { data, response, error in
//        print("Query finished.")
//
//        guard let response = response as? HTTPURLResponse, let data = data else {
//            return finishQuery(result: QueryResult(lastQuery: lastQuery, error: .connectionError), onCompletion: onCompletion)
//        }
//
//        if response.statusCode != 200 {
//            let result: QueryResult
//            if response.statusCode == 401 {
//                result = QueryResult(lastQuery: lastQuery, error: .authenticationError)
//            } else {
//                result = QueryResult(lastQuery: lastQuery, error: .parseError)
//            }
//            return finishQuery(result: result, onCompletion: onCompletion)
//        }
//
//        let html = String(data: data, encoding: .utf8)!
//
//        let result = QueryResult(html: html) ?? QueryResult(lastQuery: lastQuery, error: .parseError)
//        return finishQuery(result: result, onCompletion: onCompletion)
//    }
//
    //    task.resume()

    guard canQuery else {
        return finishQuery(result: QueryResult(lastQuery: lastQuery, error: .authenticationError), onCompletion: onCompletion)
    }

    sessionManager.request("https://websso.it.northwestern.edu/amserver/cdcservlet?goto=https://form.housing.northwestern.edu:443/foodservice/public/balancecheckplain.aspx&RequestID=14358&MajorVersion=1&MinorVersion=0&ProviderID=https://form.housing.northwestern.edu:443/amagent&IssueInstant=2017-05-01T15%3A05%3A55Z").responseString { response in
        guard response.error == nil && response.response != nil else {
            return finishQuery(result: QueryResult(lastQuery: lastQuery, error: .connectionError), onCompletion: onCompletion)
        }

        let html = response.value!
        var gotoParamValue: String
        let gotoOnFailParamValue: String
        var sunQueryParamsStringParamValue: String
        let encodedParamValue: String
        let gxCharsetParamValue: String
        do {
            let gotoParamValueMatch = try html.firstMatch(regexPattern: "<input type=\"hidden\" name=\"goto\" value=\"([a-zA-Z0-9&#;\\-=]*)\" */>")
            guard gotoParamValueMatch.count > 1 else {
                return finishQuery(result: QueryResult(lastQuery: lastQuery, error: .parseError), onCompletion: onCompletion)
            }
            gotoParamValue = gotoParamValueMatch[1]
            gotoParamValue = gotoParamValue.replacingOccurrences(of: "&#x2f;", with: "/")
            gotoParamValue = gotoParamValue.replacingOccurrences(of: "&#x3d;", with: "=")

            let gotoOnFailParamValueMatch = try html.firstMatch(regexPattern: "<input type=\"hidden\" name=\"gotoOnFail\" value=\"([a-zA-Z0-9&#;\\-=]*)\" */>")
            guard gotoOnFailParamValueMatch.count > 1 else {
                return finishQuery(result: QueryResult(lastQuery: lastQuery, error: .parseError), onCompletion: onCompletion)
            }
            gotoOnFailParamValue = gotoOnFailParamValueMatch[1]

            let sunQueryParamStringParamMatch = try html.firstMatch(regexPattern: "<input type=\"hidden\" name=\"SunQueryParamsString\" value=\"([a-zA-Z0-9&#;\\-=]*)\" */>")
            guard sunQueryParamStringParamMatch.count > 1 else {
                return finishQuery(result: QueryResult(lastQuery: lastQuery, error: .parseError), onCompletion: onCompletion)
            }
            sunQueryParamsStringParamValue = sunQueryParamStringParamMatch[1]
            // &#x2f; : /
            // &#x3d; : =
            sunQueryParamsStringParamValue = sunQueryParamsStringParamValue.replacingOccurrences(of: "&#x2f;", with: "/")
            sunQueryParamsStringParamValue = sunQueryParamsStringParamValue.replacingOccurrences(of: "&#x3d;", with: "=")

            let encodedParamMatch = try html.firstMatch(regexPattern: "<input type=\"hidden\" name=\"encoded\" value=\"([a-zA-Z0-9&#;\\-=]*)\" */>")
            guard encodedParamMatch.count > 1 else {
                return finishQuery(result: QueryResult(lastQuery: lastQuery, error: .parseError), onCompletion: onCompletion)
            }
            encodedParamValue = encodedParamMatch[1]

            let gxCharsetParamMatch = try html.firstMatch(regexPattern: "<input type=\"hidden\" name=\"gx_charset\" value=\"([a-zA-Z0-9&#;\\-=]*)\" */>")
            guard gxCharsetParamMatch.count > 1 else {
                return finishQuery(result: QueryResult(lastQuery: lastQuery, error: .parseError), onCompletion: onCompletion)
            }
            gxCharsetParamValue = gxCharsetParamMatch[1]
        } catch {
            return finishQuery(result: QueryResult(lastQuery: lastQuery, error: .parseError), onCompletion: onCompletion)
        }
        let parameters = [
            "goto" : gotoParamValue,
            "gotoOnFail" : gotoOnFailParamValue,
            "SunQueryParamsString" : sunQueryParamsStringParamValue,
            "encoded" : encodedParamValue,
            "gx_charset" : gxCharsetParamValue,
            "IDButton" : "Log+In",
            "IDToken1" : netID!,
            "IDToken2" : password!
        ]
        let request = sessionManager.request("https://websso.it.northwestern.edu/amserver/UI/Login", method: .post, parameters: parameters, encoding: URLEncoding(destination: .httpBody))
        request.responseString { response in
            guard response.error == nil && response.response != nil else {
                return finishQuery(result: QueryResult(lastQuery: lastQuery, error: .connectionError), onCompletion: onCompletion)
            }

            let laresParamValue: String
            do {
                let value = try response.value!.firstMatch(regexPattern: "<input type=\"hidden\" name=\"LARES\" value=\"([a-zA-Z0-9+=]*)\"").first
                guard value != nil else {
                    return finishQuery(result: QueryResult(lastQuery: lastQuery, error: .parseError), onCompletion: onCompletion)
                }
                laresParamValue = value!
            } catch {
                return finishQuery(result: QueryResult(lastQuery: lastQuery, error: .parseError), onCompletion: onCompletion)
            }
            let request = sessionManager.request("https://form.housing.northwestern.edu/foodservice/public/balancecheckplain.aspx", method: .post, parameters: ["LARES" : laresParamValue], encoding: URLEncoding(destination: .httpBody))
            request.responseString { response in
                guard let queryResult = QueryResult(html: response.value!) else {
                    return finishQuery(result: QueryResult(lastQuery: lastQuery, error: .parseError), onCompletion: onCompletion)
                }
                return finishQuery(result: queryResult, onCompletion: onCompletion)
            }
        }
    }
}

/// What to do when query is finished.
/// - Parameter result: The query result.
/// - Parameter onCompletion: The callback for when the query completes.
private func finishQuery(result: QueryResult, onCompletion: ((_ result: QueryResult) -> Void)) {
    lastQuery = result
    persistToUserDefaults()
    let storage = sessionManager.session.configuration.httpCookieStorage!
    for cookie in storage.cookies! {
        storage.deleteCookie(cookie)
    }
    return onCompletion(result)
}

/// The result of the last query to the server.
public var lastQuery: QueryResult?

/// The time interval before we should refresh from the server.
private let refreshThreshold: TimeInterval = 60 * 30

/// Whether we should refresh.
public var shouldRefresh: Bool {
    guard let lastQuery = lastQuery else { return true }
    return Date().timeIntervalSince(lastQuery.dateUpdated ?? lastQuery.dateRetrieved) > refreshThreshold
}

/// The date formatter for displaying dates to the user.
/// Not to be confused with the date formatter used when parsing the HTML.
var displayDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "E MMM d, h:mm a"
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

/// The app ID for AdMob.
public var adMobAppID: String {
    return adMobObject(forKey: "AdMobAppID") as! String
}

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
public private(set) var widgetArrangement: [QueryResult.WidgetDisplayItem] = [.equivalencyMeals, .equivalencyExchangeRate, .points, .catCash, .boardMeals]

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
