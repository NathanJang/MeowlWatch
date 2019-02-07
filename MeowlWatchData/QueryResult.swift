//
//  QueryResult.swift
//  MeowlWatchData
//
//  Created by Jonathan Chan on 2017-03-20.
//  Copyright © 2018 Jonathan Chan. All rights reserved.
//

import Foundation
import Kanna

/// An object representing the result from querying the server.
/// Inherits from `NSObject` and conforms to `NSCoding` to encode and decode to and from user defaults.
public class QueryResult: NSObject, NSCoding {

    /// The row title taken from upstream.
    private enum RowTitle : String {
        case name = "Name:"
        case currentPlan = "Current Plan:"
        case board = "Board:"
        case mealExchanges = "Meal Exchanges:"
        case diningDollars = "Dining Dollars:"
        case catCash = "Cat Cash:"
    }

    // MARK: Initializers

    /// Parses an HTML string from the server.
    /// The HTML string comes like:
    /**
     <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
     <html xmlns="http://www.w3.org/1999/xhtml">

     <head>
     <title>
     Balance Check, Dining Services, Northwestern University
     </title><link rel="stylesheet" href="Static/Style/screen_b.css" /><link rel="stylesheet" href="Static/Style/local.css" />
     </head>

     <body>

     <div id="pnlAnalytics">
     <script type="text/javascript">
     [Google analytics]
     </script>
     </div>

     <div id="subs-container">
     <div id="cpMain_pnlBalanceInfo">
     <table>
     <tr>
     <th>Name:</th>
     <td>Jonathan Chan</td>
     </tr>
     <tr>
     <th>Current Plan:</th>
     <td>EV UG Commuter 50/50</td>
     </tr>
     <tr>
     <th>Board:</th>
     <td>37</td>
     </tr>
     <tr>
     <th>Dining Dollars:</th>
     <td>0.00</td>
     </tr>
     <tr>
     <th>Cat Cash:</th>
     <td>1.95</td>
     </tr>
     </table>
     </div>
     </div>
     </body>
     </html>
     */
    /// - Parameter html: The HTML string.
    init?(htmlString: String) {
        self.dateRetrieved = Date()

        guard let html = try? HTML(html: htmlString.replacingOccurrences(of: "\r", with: ""), encoding: .utf8) else { return nil }
        guard let tableElement = html.at_css("#cpMain_pnlBalanceInfo > table") else { return nil }
        let rowNodes = tableElement.css("tr")
        var name: String?, currentPlanName: String?, numberOfBoardMeals: UInt?, numberOfMealExchanges: UInt?, pointsInCents: UInt?, catCashInCents: UInt?
        for rowNode in rowNodes {
            if let titleNode = rowNode.at_css("th") {
                guard let text = titleNode.text, let title = RowTitle(rawValue: text) else { continue }
                guard let stringValue = rowNode.at_css("td")?.text else { continue }
                switch title {
                case .name:
                    name = stringValue
                case .currentPlan:
                    currentPlanName = stringValue
                case .board:
                    numberOfBoardMeals = UInt(stringValue)
                case .mealExchanges:
                    numberOfMealExchanges = UInt(stringValue)
                case .diningDollars:
                    pointsInCents = UInt(toCentsWithString: stringValue)
                case .catCash:
                    catCashInCents = UInt(toCentsWithString: stringValue)
                }
            }
        }
        if let name = name, let currentPlanName = currentPlanName, let numberOfBoardMeals = numberOfBoardMeals, let numberOfMealExchanges = numberOfMealExchanges, let pointsInCents = pointsInCents, let catCashInCents = catCashInCents {
            self.name = name
            self.currentPlanName = currentPlanName
            self.numberOfBoardMeals = QueryResult.isUnlimited(currentPlanName: self.currentPlanName) ? .max - 1 : numberOfBoardMeals
            self.numberOfMealExchanges = numberOfMealExchanges
            self.pointsInCents = pointsInCents
            self.catCashInCents = catCashInCents
            self.error = nil
        } else {
            return nil
        }
    }

    /// Initialize an empty object with no error.
    private override convenience init() {
        self.init(lastQuery: nil, error: nil)
    }

    /// Initialize a possibly empty object with an error value.
    /// - Parameter error: The error value.
    /// - Parameter lastQuery: The result of the previous query.
    public init(lastQuery: QueryResult?, error: Error?) {
        self.dateRetrieved = (error != nil ? lastQuery?.dateRetrieved : Date()) ?? Date()
        self.name = lastQuery?.name ?? defaultNameString
        self.currentPlanName = lastQuery?.currentPlanName ?? defaultSubtitleString
        self.numberOfBoardMeals = lastQuery?.numberOfBoardMeals ?? 0
        self.numberOfMealExchanges = lastQuery?.numberOfMealExchanges ?? 0
        self.pointsInCents = lastQuery?.pointsInCents ?? 0
        self.catCashInCents = lastQuery?.catCashInCents ?? 0
        self.error = error
    }

    // MARK: Instance Variables

    /// The date the data was fetched from the server.
    /// Not to be confused with `dateUpdated`.
    public let dateRetrieved: Date

    /// The user's name.
    public let name: String

    /// The meal plan's name.
    public let currentPlanName: String

    /// The number of board meals left.
    public let numberOfBoardMeals: UInt

    /// The number of meal exchanges left.
    public let numberOfMealExchanges: UInt

    /// The points left, stored in cents as an integer.
    /// Example: `"11.89" -> 1189`.
    fileprivate let pointsInCents: UInt

    /// The cat cash left, stored in cents as an integer.
    /// Example: `"11.89" -> 1189`.
    public let catCashInCents: UInt

    /// A type for the different errors involved.
    public enum Error: UInt {

        /// Failed to connect or securely connect to the server.
        case connectionError

        /// Failed to authenticate with the given NetID and password.
        case authenticationError

        /// Failed to extract data from the HTML.
        case parseError

    }

    /// The error, if present.
    public let error: Error?

    // MARK: NSCoding

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(dateRetrieved, forKey: "dateRetrieved")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(currentPlanName, forKey: "currentPlanName")
        aCoder.encode(numberOfBoardMeals, forKey: "numberOfBoardMeals")
        aCoder.encode(numberOfMealExchanges, forKey: "numberOfMealExchanges")
        aCoder.encode(pointsInCents, forKey: "pointsInCents")
        aCoder.encode(catCashInCents, forKey: "catCashInCents")
        if let errorValue = error?.rawValue {
            aCoder.encode(errorValue, forKey: "error")
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        guard let dateRetrieved = aDecoder.decodeObject(forKey: "dateRetrieved") as? Date,
            let name = aDecoder.decodeObject(forKey: "name") as? String,
            let currentPlanName = aDecoder.decodeObject(forKey: "currentPlanName") as? String,
            let numberOfBoardMeals = aDecoder.decodeObject(forKey: "numberOfBoardMeals") as? UInt,
            let numberOfMealExchanges = aDecoder.decodeObject(forKey: "numberOfMealExchanges") as? UInt,
            let pointsInCents = aDecoder.decodeObject(forKey: "pointsInCents") as? UInt,
            let catCashInCents = aDecoder.decodeObject(forKey: "catCashInCents") as? UInt
            else { return nil }

        self.dateRetrieved = dateRetrieved
        self.name = name
        self.currentPlanName = currentPlanName
        self.numberOfBoardMeals = numberOfBoardMeals
        self.numberOfMealExchanges = numberOfMealExchanges
        self.pointsInCents = pointsInCents
        self.catCashInCents = catCashInCents

        if let error = aDecoder.decodeObject(forKey: "error") as? UInt {
            self.error = QueryResult.Error(rawValue: error)
        } else {
            self.error = nil
        }
    }

}

extension QueryResult {

    // MARK: Computed Properties

    /// The number of board meals as a string.
    public var boardMeals: String { return isUnlimited ? "∞" : "\(numberOfBoardMeals)" }

    /// The number of meal exchanges as a string.
    public var mealExchanges: String { return "\(numberOfMealExchanges)" }

    /// The points as a string.
    public var points: String { return "$\(pointsInCents.centsToString())" }

    /// The description for points.
    public var pointsDescription: String { return "Dining Dollars" }

    /// The description for points, also available when the controller does not have a query result object.
    public static var pointsDescription: String { return "Dining Dollars" }

    /// The total Cat Cash as a string.
    public var catCash: String { return "$\(catCashInCents.centsToString())" }

    /// Whether the user is on an unlimited meal plan or not.
    var isUnlimited: Bool { return QueryResult.isUnlimited(currentPlanName: self.currentPlanName) }

    private class func isUnlimited(currentPlanName: String) -> Bool {
        do {
            let match = try currentPlanName.firstMatch(regexPattern: "Open Access").first
            return match != nil
        } catch { return false }
    }

    /// The date retrieved as a formatted string.
    public var dateRetrievedString: String { return MeowlWatchData.displayDateFormatter.string(from: dateRetrieved) }

    public static var dateRetrievedDescription: String { return "Updated" }

    public static var dateRetrievedDescriptionForUnavailable: String { return "Never" }

    /// The message to display if there is an error.
    public var errorString: String? {
        guard let error = error else { return nil }
        switch error {
        case .connectionError:
            return mwLocalizedString("QueryErrorConnection", comment: "")
        case .authenticationError:
            return mwLocalizedString("QueryErrorAuthentication", comment: "")
        case .parseError:
            return mwLocalizedString("QueryErrorParse", comment: "")
        }
    }


    /// An enum representing the each displayed item on the widget.
    public enum WidgetDisplayItem: Int {

        /// Board meals.
        case boardMeals

        /// Meal exchanges.
        case mealExchanges

        /// Points.
        case points

        /// Cat Cash.
        case catCash
        
    }

    /// The displayed description given a widget item type and a query result to pluralize it if needed.
    /// - Parameter item: The display item type.
    /// - Parameter query: A query result.
    /// - Returns: A string to display.
    public static func description(forItem item: WidgetDisplayItem, withQuery query: QueryResult?) -> String {
        switch item {
        case .boardMeals:
            return String.localizedStringWithFormat(mwLocalizedString("MWTVCMealSwipes: %d", comment: ""), query?.numberOfBoardMeals ?? 0)
        case .mealExchanges:
            return String.localizedStringWithFormat(mwLocalizedString("MWTVCMealExchanges: %d", comment: ""), query?.numberOfMealExchanges ?? 0)
        case .points:
            return mwLocalizedString("MWTVCDiningDollars", comment: "")
        case .catCash:
            return mwLocalizedString("MWTVCCatCash", comment: "")
        }
    }

}

extension String {

    /// Given a regex pattern, this function returns an array of strings representing the first match of the pattern in `self`.
    /// The 0th element in the array is the whole string matched, if found, and subsequent elements are capture groups in the regex.
    /// This function throws if given an invalid regex pattern.
    /// - Parameter regexPattern: The regex pattern.
    /// - Returns: An array of strings representing the first match, if found.
    internal func firstMatch(regexPattern: String) throws -> [String] {
        var strings: [String] = []
        let regex = try NSRegularExpression(pattern: regexPattern, options: [.dotMatchesLineSeparators, .caseInsensitive])
        let resultOptional = regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.count))
        guard let result = resultOptional else { return [] }

        for index in 0..<result.numberOfRanges {
            let range = self.index(self.startIndex, offsetBy: result.range(at: index).location)..<self.index(self.startIndex, offsetBy: result.range(at: index).location + result.range(at: index).length)
            let string = String(self[range])
            strings.append(string)
        }

        return strings
    }

}

extension UInt {

    /// Parses a string with two decimal places and initializes a `UInt`.
    /// Returns nil if the string is invalid.
    /// Example: `"42.45" -> 4245`.
    /// - Parameter string: The string to parse.
    fileprivate init?(toCentsWithString string: String) {
        let matches: [String]
        do {
            matches = try string.firstMatch(regexPattern: "(\\d*).(\\d{2})")
        } catch { return nil }

        if matches.count != 3 { return nil }

        guard let wholeComponent = UInt(matches[1]),
            let fractionalComponent = UInt(matches[2])
        else { return nil }
        self = wholeComponent * 100 + fractionalComponent
    }

    /// Converts `self` into a two-decimal-place string representation.
    /// Example: `4245 -> "42.45"`.
    /// - Returns: The two-decimal-string representation.
    fileprivate func centsToString() -> String {
        let fractionalComponent = self % 100
        let fractionalString: String
        if fractionalComponent < 10 {
            fractionalString = "0\(fractionalComponent)"
        } else {
            fractionalString = "\(fractionalComponent)"
        }
        return "\(self / 100).\(fractionalString)"
    }
    
}

public let defaultNameString = "DefaultUserName"

/// In place of the plan when no credentials
public let defaultSubtitleString = "DefaultUserSubtitleString"
