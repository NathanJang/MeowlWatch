//
//  Datastore.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-03-17.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper

/// The main controller for getting data from the server.
struct Datastore {

    private init() {}

    /// The constant group name for shared defaults and keychain.
    private static let accessGroupName = "group.caviar.respect.MeowlWatch"

    /// The shared user defaults object.
    private static let userDefaults = UserDefaults(suiteName: accessGroupName)!

    /// The shared keychain wrapper object.
    private static let keychain = KeychainWrapper(serviceName: "caviar.respect.MeowlWatch", accessGroup: accessGroupName)

    /// Configures the datastore initially by reading from (and writing to, if necessary) user defaults and the keychain.
    static func loadFromDefaults() {
        if NSKeyedUnarchiver.class(forClassName: QueryResult.sharedClassName) != QueryResult.self {
            NSKeyedUnarchiver.setClass(QueryResult.self, forClassName: QueryResult.sharedClassName)
        }
        if let data = userDefaults.object(forKey: "lastQuery") as? Data {
            self.lastQuery = NSKeyedUnarchiver.unarchiveObject(with: data) as? QueryResult
            self.netID = keychain.string(forKey: "netID")
            self.password = keychain.string(forKey: "password")
        } else {
            // This is the first launch
            let _ = keychain.removeAllKeys()
        }

        if let intArray = userDefaults.object(forKey: "widgetArrangement") as? [Int] {
            Datastore.widgetArrangement = intArray.flatMap { return QueryResult.DisplayItem(rawValue: $0)! }
        }
    }

    /// Writes data from the datastore to user defaults.
    static func persistToUserDefaults() {
        if NSKeyedArchiver.className(for: QueryResult.self) != QueryResult.sharedClassName {
            NSKeyedArchiver.setClassName(QueryResult.sharedClassName, for: QueryResult.self)
        }

        if let lastQuery = lastQuery {
            let data = NSKeyedArchiver.archivedData(withRootObject: lastQuery)
            userDefaults.set(data, forKey: "lastQuery")
        }

        let intArray = widgetArrangement.flatMap { return $0.rawValue }
        userDefaults.set(intArray, forKey: "widgetArrangement")

        if userDefaults.responds(to: #selector(UserDefaults.synchronize)) { userDefaults.synchronize() }
    }

    /// A boolean representing whether we're prepared to query the server.
    static var canQuery: Bool { return netID != nil && !netID!.isEmpty && password != nil }

    /// The user's NetID.
    private(set) static var netID: String?

    /// The user's password.
    /// This should be stored securely and handled with care.
    private(set) static var password: String?

    /// Sets the NetID and password variables, and persists it across sessions to the keychain.
    /// - Parameter netID: The user's NetID.
    /// - Parameter password: The user's password.
    /// - Returns: Whether the result was successful.
    @discardableResult
    static func updateCredentials(netID: String?, password: String?) -> Bool {
        var success = true
        if netID == nil || netID!.isEmpty || password == nil {
            self.netID = nil
            self.password = nil

            success = keychain.removeObject(forKey: "netID") && success
            success = keychain.removeObject(forKey: "password") && success
        } else {
            let netID = netID!, password = password!
            self.netID = netID
            self.password = password

            success = keychain.set(netID, forKey: "netID") && success
            success = keychain.set(password, forKey: "password") && success
        }

        return success
    }

    /// The URL object to query at.
    /// Since this server only supports TLSv1.0, an appropriate exception should be made in `Info.plist`.
    private static let url: URL = URL(string: "https://go.dosa.northwestern.edu/uhfs/foodservice/balancecheck")!

    /// Queries the server and calls the completion handler with a query result.
    /// - Parameter onCompletion: The completion handler.
    static func query(onCompletion: @escaping (_ result: QueryResult) -> Void) {
        print("Querying...")
        guard canQuery else {
            let result = QueryResult(error: .authenticationError)
            self.lastQuery = result
            onCompletion(result)
            return
        }

        let credentialsString = "\(netID!):\(password!)"
        let credentialsData = credentialsString.data(using: .utf8)!
        let credentialsEncodedBase64 = credentialsData.base64EncodedString()
        let authorizationString = "Basic \(credentialsEncodedBase64)"
        var request = URLRequest(url: url)
        request.setValue(authorizationString, forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            print("Query finished.")

            guard let response = response as? HTTPURLResponse, let data = data else {
                return onCompletion(QueryResult(error: .connectionError))
            }

            if response.statusCode != 200 {
                let result: QueryResult
                if response.statusCode == 401 {
                    result = QueryResult(error: .authenticationError)
                } else {
                    result = QueryResult(error: .parseError)
                }
                self.lastQuery = result
                onCompletion(result)
                return
            }

            let html = String(data: data, encoding: .utf8)!

            let result = QueryResult(html: html) ?? QueryResult(error: .parseError)
            self.lastQuery = result

            onCompletion(result)
        }

        task.resume()
    }

    /// The result of the last query to the server.
    static var lastQuery: QueryResult?

    private static let refreshThreshold: TimeInterval = 60 * 30
    static var shouldRefresh: Bool {
        guard let lastQuery = lastQuery else { return true }
        return Date().timeIntervalSince(lastQuery.dateUpdated ?? lastQuery.dateRetrieved) > refreshThreshold
    }

    /// The date formatter for displaying dates to the user.
    /// Not to be confused with the date formatter used when parsing the HTML.
    static var displayDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "E MMM d, h:mm a"
        return dateFormatter
    }()

    /// Reads from the AdMobKeys property list files depending on compile-time configuration.
    /// The `AdMobKeys-Release.plist` file should be configured similarly to `AdMobKeys-Debug.plist`.
    /// - Parameter key: The key in the `plist` file.
    /// - Returns: The object stored in the `plist` file for the give key.
    private static func adMobObject(forKey key: String) -> Any {
        let path: String
        #if DEBUG
        path = Bundle.main.path(forResource: "AdMobKeys-Debug", ofType: "plist")!
        #else
        path = Bundle.main.path(forResource: "AdMobKeys-Release", ofType: "plist")!
        #endif

        return NSDictionary(contentsOfFile: path)!.value(forKey: key)!
    }

    // MARK: AdMob

    /// The app ID for AdMob.
    static var adMobAppID: String {
        return adMobObject(forKey: "AdMobAppID") as! String
    }

    /// The main ad unit ID for AdMob.
    static var adMobAdUnitID: String {
        return adMobObject(forKey: "AdMobAdUnitID") as! String
    }

    // MARK: Widget


    /// An array representing the user's arrangement of the widget items.
    /// The default is shown here, and then modified once user defaults are loaded.
    static var widgetArrangement: [QueryResult.DisplayItem] = [.equivalencyMeals, .points, .catCash, .boardMeals]

    /// Returns the display description given an item type.
    /// - Parameter item: The type of widget item.
    /// - Returns: The display string.
//    static func stringForWidgetItem(_ item: WidgetItem, plural: Bool) -> String {
//        switch item {
//        case .boardMeals:
//            return plural ? QueryResult.boardMealsPluralDescription : QueryResult.boardMealSingularDescription
//        case .equivalencyMeals:
//            return plural ? QueryResult.equivalencyMealPluralDescription : QueryResult.equivalencyMealSingularDescription
//        case .points:
//            return QueryResult.pointsDescription
//        case .catCash:
//            return QueryResult.catCashDescription
//        }
//    }

    /// Rearranges the widget arrangement preferences given indices in `widgetArrangement`.
    /// - Parameter fromIndex: The index from which the item originated.
    /// - Parameter toIndex: The index to which the item should be moved.
    static func moveWidgetArrangement(fromIndex: Int, toIndex: Int) {
        let item = widgetArrangement.remove(at: fromIndex)
        widgetArrangement.insert(item, at: toIndex)
    }

}
