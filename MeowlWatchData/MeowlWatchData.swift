//
//  MeowlWatchData.swift
//  MeowlWatchData
//
//  Created by Jonathan Chan on 2017-03-17.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper


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

/// Queries the server and calls the completion handler with a query result.
/// - Parameter onCompletion: The completion handler.
public func query(onCompletion: (@escaping (_ result: QueryResult) -> Void)) {
    print("Querying...")
    guard canQuery else {
        return finishQuery(result: QueryResult(lastQuery: lastQuery, error: .authenticationError), onCompletion: onCompletion)
    }

    let credentialsString = "\(netID!):\(password!)"
    let credentialsData = credentialsString.data(using: .utf8)!
    let credentialsEncodedBase64 = credentialsData.base64EncodedString()
    let authorizationString = "Basic \(credentialsEncodedBase64)"
    var request = URLRequest(url: url)
    request.setValue(authorizationString, forHTTPHeaderField: "Authorization")

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        print("Query finished.")

        guard let response = response as? HTTPURLResponse, let data = data else {
            return finishQuery(result: QueryResult(lastQuery: lastQuery, error: .connectionError), onCompletion: onCompletion)
        }

        if response.statusCode != 200 {
            let result: QueryResult
            if response.statusCode == 401 {
                result = QueryResult(lastQuery: lastQuery, error: .authenticationError)
            } else {
                result = QueryResult(lastQuery: lastQuery, error: .parseError)
            }
            return finishQuery(result: result, onCompletion: onCompletion)
        }

        let html = String(data: data, encoding: .utf8)!

        let result = QueryResult(html: html) ?? QueryResult(lastQuery: lastQuery, error: .parseError)
        return finishQuery(result: result, onCompletion: onCompletion)
    }

    task.resume()
}

/// What to do when query is finished.
/// - Parameter result: The query result.
/// - Parameter onCompletion: The callback for when the query completes.
private func finishQuery(result: QueryResult, onCompletion: ((_ result: QueryResult) -> Void)) {
    lastQuery = result
    persistToUserDefaults()
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

// MARK:- Dining Halls

/// An enum representing each dining hall.
public enum DiningHall: String {

    case allison = "Allison"

    case elder = "Elder"

    case plexEast = "Plex East"

    case plexWest = "Plex West"

    case hinman = "Hinman"

    case sargent = "Sargent"

}

/// An enum representing each cafe or C-Store.
public enum CafeOrCStore: String {

    case plex = "Plex C-Store"

    case frans = "Fran's Cafe at Hinman"

    case hinmanCStore = "Hinman C-Store"

    case kresge = "Kresge Cafe"

    case einstein = "Einstein at Pancoe"

    case bergson = "Cafe Bergson"

    case techExpress = "Tech Express"

    case lisas = "Lisa's Cafe at Slivka"

}

/// An enum representing each location at Norris.
public enum NorrisLocation: String {

    case internationalStation = "Intl. Station"

    case catShack = "Cat Shack"

    case wildcatDen = "Wildcat Den"

    case northshorePizza = "Northshore Pizza"

    case pawsNGo = "Paws 'n Go C-Store"

    case subway = "Subway"

    case starbucks = "Norbucks"

    case dunkinDonuts = "Dunkin' Donuts"

    case frontera = "Frontera"

}

/// An enum representing the status of dining halls.
public enum DiningHallSession: String {

    case breakfast = "Breakfast"

    case continentalBreakfast = "Continental Breakfast"

    case brunch = "Brunch"

    case lunch = "Lunch"

    case liteLunch = "Lite Lunch"

    case dinner = "Dinner"

    case lateNight = "Late Night"

    case closed = "Closed"

}

/// The calendar used by dining halls.
/// Gregorian calendar in Chicago.
internal let diningCalendar: Calendar = { () -> Calendar in
    var calendar = Calendar(identifier: Calendar.Identifier.gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Chicago")!
    return calendar
}()

/// The dining session at the specified dining hall for the specified date.
/// - Param diningHall: The dining hall in consideration.
/// - Param date: The date to consider.
/// - Returns: The dining hall session.
public func diningSession(for diningHall: DiningHall, at date: Date = Date()) -> DiningHallSession {
    let calendar = diningCalendar

    let dateAtStartOfDay = calendar.startOfDay(for: date)
    let dayOfWeek = calendar.component(.weekday, from: dateAtStartOfDay)

    switch diningHall {
    case .allison:
        if dayOfWeek == 1 { // Sunday
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1400 = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1700 = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2000 = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt1100 {
                return .closed
            } else if date < dateAt1400 {
                return .brunch
            } else if date < dateAt1700 {
                return .liteLunch
            } else if date < dateAt2000 {
                return .dinner
            } else {
                return .closed
            }
        } else if dayOfWeek <= 5 { // Monday - Thursday
            let dateAt0730 = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: dateAtStartOfDay)!
            let dateAt1000 = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1300 = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1700 = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2000 = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0730 {
                return .closed
            } else if date < dateAt1000 {
                return .breakfast
            } else if date < dateAt1100 {
                return .continentalBreakfast
            } else if date < dateAt1300 {
                return .lunch
            } else if date < dateAt1700 {
                return .liteLunch
            } else if date < dateAt2000 {
                return .dinner
            } else {
                return .closed
            }
        } else if dayOfWeek == 6 { // Friday
            let dateAt0730 = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: dateAtStartOfDay)!
            let dateAt1000 = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1300 = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1700 = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1900 = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0730 {
                return .closed
            } else if date < dateAt1000 {
                return .breakfast
            } else if date < dateAt1100 {
                return .continentalBreakfast
            } else if date < dateAt1300 {
                return .lunch
            } else if date < dateAt1700 {
                return .liteLunch
            } else if date < dateAt1900 {
                return .dinner
            } else {
                return .closed
            }
        } else { // Saturday
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1400 = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1700 = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1900 = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt1100 {
                return .closed
            } else if date < dateAt1400 {
                return .brunch
            } else if date < dateAt1700 {
                return .liteLunch
            } else if date < dateAt1900 {
                return .dinner
            } else {
                return .closed
            }
        }


    case .elder:
        if dayOfWeek == 1 || dayOfWeek == 7 { // Sunday / Saturday
            return .closed
        } else if dayOfWeek <= 5 { // Monday - Thursday
            let dateAt0700 = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt0900 = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1700 = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1900 = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0700 {
                return .closed
            } else if date < dateAt0900 {
                return .breakfast
            } else if date < dateAt1700 {
                return .closed
            } else if date < dateAt1900 {
                return .dinner
            } else {
                return .closed
            }
        } else { // Friday
            let dateAt0700 = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt0900 = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0700 {
                return .closed
            } else if date < dateAt0900 {
                return .breakfast
            } else {
                return .closed
            }
        }

    case .plexEast:
        if dayOfWeek == 1 { // Sunday
            return .closed
        } else if dayOfWeek <= 5 { // Monday - Thursday
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1300 = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1700 = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2000 = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt1100 {
                return .closed
            } else if date < dateAt1300 {
                return .lunch
            } else if date < dateAt1700 {
                return .closed
            } else if date < dateAt2000 {
                return .dinner
            } else {
                return .closed
            }
        } else if dayOfWeek == 6 { // Friday
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1300 = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1700 = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1900 = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt1100 {
                return .closed
            } else if date < dateAt1300 {
                return .lunch
            } else if date < dateAt1700 {
                return .closed
            } else if date < dateAt1900 {
                return .dinner
            } else {
                return .closed
            }
        } else { // Saturday
            return .closed
        }

    case .plexWest:
        if dayOfWeek == 1 { // Sunday
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1400 = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1700 = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2000 = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2330 = calendar.date(bySettingHour: 23, minute: 30, second: 0, of: dateAtStartOfDay)!

            if date < dateAt1100 {
                return .closed
            } else if date < dateAt1400 {
                return .brunch
            } else if date < dateAt1700 {
                return .liteLunch
            } else if date < dateAt2000 {
                return .dinner
            } else if date < dateAt2330 {
                return .lateNight
            } else {
                return .closed
            }
        } else if dayOfWeek <= 5 { // Monday - Thursday
            let dateAt0730 = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: dateAtStartOfDay)!
            let dateAt1000 = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1300 = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1700 = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2000 = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2330 = calendar.date(bySettingHour: 23, minute: 30, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0730 {
                return .closed
            } else if date < dateAt1000 {
                return .breakfast
            } else if date < dateAt1100 {
                return .continentalBreakfast
            } else if date < dateAt1300 {
                return .lunch
            } else if date < dateAt1700 {
                return .liteLunch
            } else if date < dateAt2000 {
                return .dinner
            } else if date < dateAt2330 {
                return .lateNight
            } else {
                return .closed
            }
        } else if dayOfWeek == 6 { // Friday
            let dateAt0730 = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: dateAtStartOfDay)!
            let dateAt1000 = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1300 = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1700 = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1900 = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0730 {
                return .closed
            } else if date < dateAt1000 {
                return .breakfast
            } else if date < dateAt1100 {
                return .continentalBreakfast
            } else if date < dateAt1300 {
                return .lunch
            } else if date < dateAt1700 {
                return .liteLunch
            } else if date < dateAt1900 {
                return .dinner
            } else {
                return .closed
            }
        } else { // Saturday
            let dateAt0730 = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: dateAtStartOfDay)!
            let dateAt1000 = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1400 = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1700 = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1900 = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0730 {
                return .closed
            } else if date < dateAt1000 {
                return .breakfast
            } else if date < dateAt1100 {
                return .continentalBreakfast
            } else if date < dateAt1400 {
                return .brunch
            } else if date < dateAt1700 {
                return .liteLunch
            } else if date < dateAt1900 {
                return .dinner
            } else {
                return .closed
            }
        }

    case .hinman:
        if dayOfWeek == 1 { // Sunday
            return .closed
        } else if dayOfWeek <= 5 { // Monday - Thursday
            let dateAt0730 = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: dateAtStartOfDay)!
            let dateAt1000 = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1300 = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1700 = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2000 = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0730 {
                return .closed
            } else if date < dateAt1000 {
                return .breakfast
            } else if date < dateAt1100 {
                return .continentalBreakfast
            } else if date < dateAt1300 {
                return .lunch
            } else if date < dateAt1700 {
                return .liteLunch
            } else if date < dateAt2000 {
                return .dinner
            } else {
                return .closed
            }
        } else if dayOfWeek == 6 {
            let dateAt0730 = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: dateAtStartOfDay)!
            let dateAt1000 = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1300 = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1700 = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1900 = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0730 {
                return .closed
            } else if date < dateAt1000 {
                return .breakfast
            } else if date < dateAt1100 {
                return .continentalBreakfast
            } else if date < dateAt1300 {
                return .lunch
            } else if date < dateAt1700 {
                return .liteLunch
            } else if date < dateAt1900 {
                return .dinner
            } else {
                return .closed
            }
        } else { // Saturday
            return .closed
        }
        
    case .sargent:
        if dayOfWeek == 1 { // Sunday
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1400 = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1700 = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2000 = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2330 = calendar.date(bySettingHour: 23, minute: 30, second: 0, of: dateAtStartOfDay)!

            if date < dateAt1100 {
                return .closed
            } else if date < dateAt1400 {
                return .brunch
            } else if date < dateAt1700 {
                return .liteLunch
            } else if date < dateAt2000 {
                return .dinner
            } else if date < dateAt2330 {
                return .lateNight
            } else {
                return .closed
            }
        } else if dayOfWeek <= 5 { // Monday - Thursday
            let dateAt0730 = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: dateAtStartOfDay)!
            let dateAt1000 = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1300 = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1700 = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2000 = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2330 = calendar.date(bySettingHour: 23, minute: 30, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0730 {
                return .closed
            } else if date < dateAt1000 {
                return .breakfast
            } else if date < dateAt1100 {
                return .continentalBreakfast
            } else if date < dateAt1300 {
                return .lunch
            } else if date < dateAt1700 {
                return .liteLunch
            } else if date < dateAt2000 {
                return .dinner
            } else if date < dateAt2330 {
                return .lateNight
            } else {
                return .closed
            }
        } else if dayOfWeek == 6 { // Friday
            let dateAt0730 = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: dateAtStartOfDay)!
            let dateAt1000 = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1300 = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1700 = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1900 = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0730 {
                return .closed
            } else if date < dateAt1000 {
                return .breakfast
            } else if date < dateAt1100 {
                return .continentalBreakfast
            } else if date < dateAt1300 {
                return .lunch
            } else if date < dateAt1700 {
                return .liteLunch
            } else if date < dateAt1900 {
                return .dinner
            } else {
                return .closed
            }
        } else { // Saturday
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1400 = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1700 = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2000 = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2330 = calendar.date(bySettingHour: 23, minute: 30, second: 0, of: dateAtStartOfDay)!

            if date < dateAt1100 {
                return .closed
            } else if date < dateAt1400 {
                return .brunch
            } else if date < dateAt1700 {
                return .liteLunch
            } else if date < dateAt2000 {
                return .dinner
            } else if date < dateAt2330 {
                return .lateNight
            } else {
                return .closed
            }
        }
    }
}

/// Whether the given cafe or C-Store is open.
/// - Param cafeOrCStore: The cafe or C-Store to consider.
/// - Param date: The date to consider.
/// - Returns: Whether it is open.
public func isOpen(_ cafeOrCStore: CafeOrCStore, at date: Date = Date()) -> Bool {
    let calendar = diningCalendar

    let dateAtStartOfDay = calendar.startOfDay(for: date)
    let dayOfWeek = calendar.component(.weekday, from: dateAtStartOfDay)

    switch cafeOrCStore {
    case .plex:
        if dayOfWeek == 1 { // Sunday
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt1100 {
                return false
            } else {
                return true
            }
        } else if dayOfWeek <= 5 { // Monday - Thursday
            let dateAt0730 = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0730 {
                return false
            } else {
                return true
            }
        } else { // Friday - Saturday
            let dateAt0730 = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: dateAtStartOfDay)!
            let dateAt1900 = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0730 {
                return false
            } else if date < dateAt1900 {
                return true
            } else {
                return false
            }
        }

    case .hinmanCStore:
        if dayOfWeek == 1 { // Sunday
            let dateAt2000 = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt2000 {
                return false
            } else {
                return true
            }
        } else if dayOfWeek <= 5 { // Monday - Thursday
            let dateAt0300 = calendar.date(bySettingHour: 3, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt0730 = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0300 {
                return true
            } else if date < dateAt0730 {
                return false
            } else {
                return true
            }
        } else if dayOfWeek == 6 { // Friday
            let dateAt0300 = calendar.date(bySettingHour: 3, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt0730 = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: dateAtStartOfDay)!
            let dateAt1900 = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0300 {
                return true
            } else if date < dateAt0730 {
                return false
            } else if date < dateAt1900 {
                return true
            } else {
                return false
            }
        } else { // Saturday
            return false
        }

    case .frans:
        if dayOfWeek == 1 { // Sunday
            let dateAt2000 = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt2000 {
                return false
            } else {
                return true
            }
        } else if dayOfWeek <= 5 { // Monday - Thursday
            let dateAt0300 = calendar.date(bySettingHour: 3, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2000 = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0300 {
                return true
            } else if date < dateAt2000 {
                return false
            } else {
                return true
            }
        } else if dayOfWeek == 6 { // Friday
            let dateAt0300 = calendar.date(bySettingHour: 3, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0300 {
                return true
            } else {
                return false
            }
        } else { // Saturday
            return false
        }

    case .kresge:
        if dayOfWeek == 1 { // Sunday
            return false
        } else if dayOfWeek <= 6 { // Monday - Friday
            let dateAt0800 = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1500 = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0800 {
                return false
            } else if date < dateAt1500 {
                return true
            } else {
                return false
            }
        } else { // Saturday
            return false
        }

    case .einstein:
        if dayOfWeek == 1 { // Sunday
            return false
        } else if dayOfWeek <= 5 { // Monday - Thursday
            let dateAt0800 = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1600 = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0800 {
                return false
            } else if date < dateAt1600 {
                return true
            } else {
                return false
            }
        } else if dayOfWeek == 6 { // Friday
            let dateAt0800 = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1500 = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0800 {
                return false
            } else if date < dateAt1500 {
                return true
            } else {
                return false
            }
        } else { // Saturday
            return false
        }

    case .bergson:
        if dayOfWeek == 1 { // Sunday
            let dateAt1700 = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt1700 {
                return false
            } else {
                return true
            }
        } else if dayOfWeek <= 5 { // Monday - Thursday
            let dateAt0830 = calendar.date(bySettingHour: 8, minute: 30, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0830 {
                return false
            } else {
                return false
            }
        } else if dayOfWeek == 6 { // Friday
            let dateAt0830 = calendar.date(bySettingHour: 8, minute: 30, second: 0, of: dateAtStartOfDay)!
            let dateAt1500 = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0830 {
                return false
            } else if date < dateAt1500 {
                return true
            } else {
                return false
            }
        } else { // Saturday
            let dateAt1200 = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1600 = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt1200 {
                return false
            } else if date < dateAt1600 {
                return true
            } else {
                return false
            }
        }

    case .techExpress:
        if dayOfWeek == 1 { // Sunday
            return false
        } else if dayOfWeek <= 5 { // Monday - Thursday
            let dateAt0730 = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: dateAtStartOfDay)!
            let dateAt1830 = calendar.date(bySettingHour: 18, minute: 30, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0730 {
                return false
            } else if date < dateAt1830 {
                return true
            } else {
                return false
            }
        } else if dayOfWeek == 6 { // Friday
            let dateAt0730 = calendar.date(bySettingHour: 7, minute: 30, second: 0, of: dateAtStartOfDay)!
            let dateAt1500 = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0730 {
                return false
            } else if date < dateAt1500 {
                return true
            } else {
                return false
            }
        } else { // Saturday
            return false
        }
        
    case .lisas:
        if dayOfWeek <= 6 { // Sunday - Friday
            let dateAt0300 = calendar.date(bySettingHour: 3, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt0800 = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0300 {
                return true
            } else if date < dateAt0800 {
                return false
            } else {
                return true
            }
        } else { // Saturday
            let dateAt0300 = calendar.date(bySettingHour: 3, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0300 {
                return true
            } else if date < dateAt1100 {
                return false
            } else {
                return true
            }
        }
    }
}

/// Whether the given Norris location is open.
/// - Param norrisLocation: The Norris location to consider.
/// - Param date: The date to consider.
/// - Returns: Whether it is open.
public func isOpen(_ norrisLocation: NorrisLocation, at date: Date = Date()) -> Bool {
    let calendar = diningCalendar

    let dateAtStartOfDay = calendar.startOfDay(for: date)
    let dayOfWeek = calendar.component(.weekday, from: dateAtStartOfDay)

    switch norrisLocation {
    case .internationalStation:
        if dayOfWeek == 1 { // Sunday
            let dateAt1200 = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1500 = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt1200 {
                return false
            } else if date < dateAt1500 {
                return true
            } else {
                return false
            }
        } else if dayOfWeek <= 5 { // Monday - Thursday
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1900 = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt1100 {
                return false
            } else if date < dateAt1900 {
                return true
            } else {
                return false
            }
        } else if dayOfWeek == 6 { // Friday
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1500 = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt1100 {
                return false
            } else if date < dateAt1500 {
                return true
            } else {
                return false
            }
        } else { // Saturday
            return false
        }

    case .catShack:
        if dayOfWeek == 1 { // Sunday
            let dateAt1200 = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1500 = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt1200 {
                return false
            } else if date < dateAt1500 {
                return true
            } else {
                return false
            }
        } else if dayOfWeek <= 5 { // Monday - Thursday
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1900 = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt1100 {
                return false
            } else if date < dateAt1900 {
                return true
            } else {
                return false
            }
        } else if dayOfWeek == 6 { // Friday
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1500 = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt1100 {
                return false
            } else if date < dateAt1500 {
                return true
            } else {
                return false
            }
        } else { // Saturday
            return false
        }

    case .wildcatDen:
        if dayOfWeek == 1 { // Sunday
            return false
        } else if dayOfWeek <= 5 { // Monday - Thursday
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1900 = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt1100 {
                return false
            } else if date < dateAt1900 {
                return true
            } else {
                return false
            }
        } else if dayOfWeek == 6 { // Friday
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1500 = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt1100 {
                return false
            } else if date < dateAt1500 {
                return true
            } else {
                return false
            }
        } else { // Saturday
            return false
        }

    case .northshorePizza:
        if dayOfWeek == 1 { // Sunday
            return false
        } else if dayOfWeek <= 5 { // Monday - Thursday
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2300 = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt1100 {
                return false
            } else if date < dateAt2300 {
                return true
            } else {
                return false
            }
        } else { // Friday - Saturday
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2100 = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt1100 {
                return false
            } else if date < dateAt2100 {
                return true
            } else {
                return false
            }
        }

    case .pawsNGo:
        if dayOfWeek == 1 { // Sunday
            let dateAt1000 = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2300 = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt1000 {
                return false
            } else if date < dateAt2300 {
                return true
            } else {
                return false
            }
        } else if dayOfWeek <= 5 { // Monday - Thursday
            let dateAt0800 = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2300 = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0800 {
                return false
            } else if date < dateAt2300 {
                return true
            } else {
                return false
            }
        } else { // Friday - Saturday
            let dateAt0800 = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2345 = calendar.date(bySettingHour: 23, minute: 45, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0800 {
                return false
            } else if date < dateAt2345 {
                return true
            } else {
                return false
            }
        }

    case .subway:
        let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
        let dateAt2100 = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: dateAtStartOfDay)!

        if date < dateAt1100 {
            return false
        } else if date < dateAt2100 {
            return true
        } else {
            return false
        }

    case .starbucks:
        if dayOfWeek == 1 { // Sunday
            let dateAt1000 = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2345 = calendar.date(bySettingHour: 23, minute: 45, second: 0, of: dateAtStartOfDay)!

            if date < dateAt1000 {
                return false
            } else if date < dateAt2345 {
                return true
            } else {
                return false
            }
        } else if dayOfWeek <= 5 { // Monday - Thursday
            let dateAt0800 = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2345 = calendar.date(bySettingHour: 23, minute: 45, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0800 {
                return false
            } else if date < dateAt2345 {
                return true
            } else {
                return false
            }
        } else if dayOfWeek == 6 { // Friday
            let dateAt0800 = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2100 = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0800 {
                return false
            } else if date < dateAt2100 {
                return true
            } else {
                return false
            }
        } else { // Saturday
            let dateAt0900 = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2100 = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0900 {
                return false
            } else if date < dateAt2100 {
                return true
            } else {
                return false
            }
        }

    case .dunkinDonuts:
        if dayOfWeek == 1 { // Sunday
            let dateAt1000 = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2345 = calendar.date(bySettingHour: 23, minute: 45, second: 0, of: dateAtStartOfDay)!

            if date < dateAt1000 {
                return false
            } else if date < dateAt2345 {
                return true
            } else {
                return false
            }
        } else if dayOfWeek <= 5 { // Monday - Thursday
            let dateAt0800 = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2345 = calendar.date(bySettingHour: 23, minute: 45, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0800 {
                return false
            } else if date < dateAt2345 {
                return true
            } else {
                return false
            }
        } else if dayOfWeek == 6 { // Friday
            let dateAt0800 = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2100 = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0800 {
                return false
            } else if date < dateAt2100 {
                return true
            } else {
                return false
            }
        } else { // Saturday
            let dateAt0900 = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt2100 = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt0900 {
                return false
            } else if date < dateAt2100 {
                return true
            } else {
                return false
            }
        }

    case .frontera:
        if dayOfWeek == 1 { // Sunday
            return false
        } else if dayOfWeek <= 6 { // Monday - Friday
            let dateAt1100 = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dateAtStartOfDay)!
            let dateAt1500 = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: dateAtStartOfDay)!

            if date < dateAt1100 {
                return false
            } else if date < dateAt1500 {
                return true
            } else {
                return false
            }
        } else { // Saturday
            return false
        }
    }
}
