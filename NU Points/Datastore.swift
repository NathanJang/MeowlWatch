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
    static var canQuery: Bool { return netID != nil && password != nil }

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
        self.netID = netID
        self.password = password
        if shouldPersist {
            var success: Bool
            if netID == nil || password == nil {
                success = KeychainWrapper.standard.removeObject(forKey: "netID") && KeychainWrapper.standard.removeObject(forKey: "password")
            } else {
                success = KeychainWrapper.standard.set(netID!, forKey: "netID") && KeychainWrapper.standard.set(password!, forKey: "password")
            }
            return success
        } else { return true }
    }

    /// The URL object to query at.
    /// Since this server only supports TLSv1.0, an appropriate exception should be made in `Info.plist`.
    private static let url: URL = URL(string: "https://go.dosa.northwestern.edu/uhfs/foodservice/balancecheck")!

    /// Queries the server and calls the completion handler with a query result.
    /// - Parameter onCompletion: The completion handler.
    static func query(onCompletion: @escaping (_ result: QueryResult) -> Void) {
        print("Querying...")
        guard canQuery else { return onCompletion(QueryResult(error: .authenticationError)) }

        let credentialsString = "\(netID!):\(password!)"
        let credentialsData = credentialsString.data(using: .utf8)!
        let credentialsEncodedBase64 = credentialsData.base64EncodedString()
        let authorizationString = "Basic \(credentialsEncodedBase64)"
        var request = URLRequest(url: url)
        request.setValue(authorizationString, forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            print("Query finished.")

            guard let response = response as? HTTPURLResponse, let data = data else { return onCompletion(QueryResult(error: .connectionError)) }

            if response.statusCode == 401 { return onCompletion(QueryResult(error: .authenticationError)) }
            else if response.statusCode != 200 { return onCompletion(QueryResult(error: .parseError)) }

            let html = String(data: data, encoding: .utf8)!

            let result = QueryResult(html: html)
            self.lastQuery = result

            onCompletion(result ?? QueryResult(error: .parseError))
        }

        task.resume()
    }

    /// The result of the last query to the server.
    static var lastQuery: QueryResult?

    /// The date formatter for displaying dates to the user.
    /// Not to be confused with the date formatter used when parsing the HTML.
    static var displayDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E MMM d, h:mm a"
        return dateFormatter
    }()

}
