//
//  QueryResult.swift
//  MeowlWatchData
//
//  Created by Jonathan Chan on 2017-03-20.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import Foundation

/// An object representing the result from querying the server.
/// Inherits from `NSObject` and conforms to `NSCoding` to encode and decode to and from user defaults.
public class QueryResult: NSObject, NSCoding {

    // MARK: Initializers

    /// Parses an HTML string from the server.
    /// The HTML string comes like:
    /**
     <table>
     <tr>
     <th>Name:</th>
     <td>Jonathan Chan</td>
     </tr>
     <tr>
     <th>Current Plan:</th>
     <td>EV UG Base 14</td>
     </tr>
     <tr>
     <th>Board:</th>
     <td>14</td>
     </tr>
     <tr>
     <th>Dining Dollars:</th>
     <td>225.00</td>
     </tr>
     <tr>
     <th>Cat Cash:</th>
     <td>0.00</td>
     </tr>
     </table>
     */
    /// - Parameter html: The HTML string.
    init?(html: String) {
        self.dateRetrieved = Date()

        var html = html

        let matches: [String]

        do {
            html = html.replacingOccurrences(of: "\r", with: "")
            guard let contentString = try html.firstMatch(regexPattern: "<table>.*</table>").first else { return nil }
            matches = try contentString.firstMatch(regexPattern: "<th>Name:</th>.*<td>([A-Za-z ]*)</td>.*<th>Current Plan:</th>.*<td>([A-Za-z/\\d ]*)</td>.*<th>Board:</th>.*<td>(\\d*)</td>.*<th>Dining Dollars:</th>.*<td>(\\d*.\\d{2})</td>.*<th>Cat Cash:</th>.*<td>(\\d*.\\d{2})</td>")
        } catch { return nil }

        guard matches.count == 6 else { return nil }

        self.name = matches[1]
        self.currentPlanName = matches[2]
        guard let numberOfBoardMeals = UInt(matches[3]),
            let pointsInCents = UInt(toCentsWithString: matches[4]),
            let catCashInCents = UInt(toCentsWithString: matches[5])
        else { return nil }

        self.numberOfBoardMeals = numberOfBoardMeals
        self.pointsInCents = pointsInCents
        self.catCashInCents = catCashInCents

        self.error = nil
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
    fileprivate let numberOfBoardMeals: UInt

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
            let pointsInCents = aDecoder.decodeObject(forKey: "pointsInCents") as? UInt,
            let catCashInCents = aDecoder.decodeObject(forKey: "catCashInCents") as? UInt
            else { return nil }

        self.dateRetrieved = dateRetrieved
        self.name = name
        self.currentPlanName = currentPlanName
        self.numberOfBoardMeals = numberOfBoardMeals
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

    /// Whether we should display the board meals description in plural form.
    private var boardMealsIsPlural: Bool { return numberOfBoardMeals != 1 }

    /// The description for 1 board meal.
    private static var boardMealSingularDescription: String { return "Meal Swipe" }

    /// The description for many board meals.
    private static var boardMealsPluralDescription: String { return "Meal Swipes" }

    /// The pluralized/singular description for board meals.
    var boardMealsDescription: String { return boardMealsIsPlural ? QueryResult.boardMealsPluralDescription : QueryResult.boardMealSingularDescription }

    /// The points as a string.
    public var points: String { return "$\(pointsInCents.centsToString())" }

    /// The description for points.
    public var pointsDescription: String { return "Dining Dollars" }

    /// The description for points, also available when the controller does not have a query result object.
    public static var pointsDescription: String { return "Dining Dollars" }

    /// The total Cat Cash as a string.
    public var catCash: String { return "$\(catCashInCents.centsToString())" }

    /// The description for Cat Cash.
    public var catCashDescription: String { return "Cat Cash" }

    /// The description for Cat Cash, also available when the controller does not have a query result object.
    public static var catCashDescription: String { return "Cat Cash" }

    /// Whether the user is on an unlimited meal plan or not.
    var isUnlimited: Bool {
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
            return "Unable to connect to the server. Please make sure your device is connected to the internet."
        case .authenticationError:
            return "Unable to sign in to Northwestern. Please tap \"Account\" to make sure your NetID and password are correct."
        case .parseError:
            return "An unexpected error occurred. Please try again. If the issue persists, please contact the developer through Settings > Send Feedback."
        }
    }


    /// An enum representing the each displayed item on the widget.
    public enum WidgetDisplayItem: Int {

        /// Board meals.
        case boardMeals

        /// Points.
        case points

        /// Cat Cash.
        case catCash
        
    }

    /// The displayed description given a widget item type.
    /// - Parameter item: The display item type.
    /// - Returns: A string to display.
    private func description(forItem item: WidgetDisplayItem) -> String {
        switch item {
        case .boardMeals:
            return boardMealsDescription
        case .points:
            return QueryResult.pointsDescription
        case .catCash:
            return QueryResult.catCashDescription
        }
    }

    /// The displayed description given a widget item type and a query result to pluralize it if needed.
    /// - Parameter item: The display item type.
    /// - Parameter query: A query result.
    /// - Returns: A string to display.
    public static func description(forItem item: WidgetDisplayItem, withQuery query: QueryResult?) -> String {
        switch item {
        case .boardMeals:
            return query?.description(forItem: .boardMeals) ?? boardMealsPluralDescription
        case .points:
            return pointsDescription
        case .catCash:
            return catCashDescription
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
        let resultOptional = regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.characters.count))
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

public let defaultNameString = "Your Name"

/// In place of the plan when no credentials
public let defaultSubtitleString = "Tap Here To Get Started"
