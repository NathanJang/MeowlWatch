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

    /// A boolean representing whether we're prepared to query the server.
    static var canQuery: Bool { return netID != nil && !netID!.isEmpty && password != nil }

    /// The user's NetID.
    private(set) static var netID: String?

    /// The user's password.
    /// This should be stored securely and handled with care.
    private(set) static var password: String?

    /// Sets the NetID and password variables, and persists it across sessions to the keychain if required.
    /// - Parameter netID: The user's NetID.
    /// - Parameter password: The user's password.
    /// - Parameter shouldPersist: Whether to persist the result to the keychain.
    /// - Returns: Whether the result was successful.
    @discardableResult
    static func updateCredentials(netID: String?, password: String?, persistToKeychain shouldPersist: Bool) -> Bool {
        var success = true
        if netID == nil || netID!.isEmpty || password == nil {
            self.netID = nil
            self.password = nil

            if shouldPersist {
                success = KeychainWrapper.standard.removeObject(forKey: "netID") && success
                success = KeychainWrapper.standard.removeObject(forKey: "password") && success
            }
        } else {
            let netID = netID!, password = password!
            self.netID = netID
            self.password = password

            if shouldPersist {
                success = KeychainWrapper.standard.set(netID, forKey: "netID") && success
                success = KeychainWrapper.standard.set(password, forKey: "password") && success
            }
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

    /// The app ID for AdMob.
    static var adMobAppID: String {
        return adMobObject(forKey: "AdMobAppID") as! String
    }

    /// The main ad unit ID for AdMob.
    static var adMobAdUnitID: String {
        return adMobObject(forKey: "AdMobAdUnitID") as! String
    }

}
