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

    /// The constant class name of this class with the module name.
//    static let sharedClassName = "MeowlWatch.QueryResult"

    // MARK: Initializers

    /// Parses an HTML string from the server.
    /// The HTML string comes like:
    /**
     <!--startindex-->
     <!-- InstanceBeginEditable name="contentArea" -->

     <h1>Balance Check</h1>

     <table style="width: 400px;">
     <tr>
     <td><b>Name:</b></td>
     <td>Jonathan Chan</td>
     </tr>
     <tr>
     <td><b>Current Plan:</b></td>
     <td>Cat Cash</td>
     </tr>
     <tr>
     <td><b>Board Meals:</b></td>
     <td>0</td>
     </tr>
     <tr>
     <td><b>Equivalency Meals:</b></td>
     <td>0</td>
     </tr>
     <tr>
     <td><b>Points:</b></td>
     <td>0.00</td>
     </tr>
     <tr>
     <td><b>Cat Cash:</b></td>
     <td>7.42</td>
     </tr>
     <tr>
     <td><b>Cat Cash Bonus:</b></td>
     <td>0.00</td>
     </tr>
     </table>
     <br />
     <span style="color: gray;">Last Updated Monday, March 20, 2017 12:00 AM</span>

     </div>
     <!--stopindex-->
     */
    /// - Parameter html: The HTML string.
    init?(html: String) {
        self.dateRetrieved = Date()

        let contentString: String
        let matches: [String]

        do {
            contentString = try html.firstMatch(regexPattern: "<!--startindex-->.*<!--stopindex-->").first!
            matches = try contentString.firstMatch(regexPattern: "<td.*Name:.*</td>.*<td>([A-Za-z ]*)</td>.*<td.*Current Plan:.*</td>.*<td>([A-Za-z\\d ]*)</td>.*<td.*Board Meals:.*</td>.*<td>(\\d*)</td>.*<td.*Equivalency Meals:.*</td>.*<td>(\\d*)</td>.*<td.*Points:.*</td>.*<td>(\\d*.\\d{2})</td>.*<td.*Cat Cash:.*</td>.*<td>(\\d*.\\d{2})</td>.*<td.*Cat Cash Bonus:.*</td>.*<td>(\\d*.\\d{2})</td>.*Last Updated ([A-Za-z\\d,: ]*)")
        } catch { return nil }

        guard matches.count == 9 else { return nil }

        self.name = matches[1]
        self.currentPlanName = matches[2]
        self.numberOfBoardMeals = UInt(matches[3])!
        self.numberOfEquivalencyMeals = UInt(matches[4])!
        self.pointsInCents = UInt(toCentsWithString: matches[5])!
        self.catCashInCents = UInt(toCentsWithString: matches[6])!
        self.catCashBonusInCents = UInt(toCentsWithString: matches[7])!

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "EEEE, MMMM d, yyyy hh:mm a"
        self.dateUpdated = dateFormatter.date(from: matches[8])

        self.error = nil
    }

    /// Initialize an empty object with no error.
    private override convenience init() {
        self.init(error: nil)
    }

    /// Initialize an empty object with an error value.
    /// - Parameter error: The error value.
    init(error: Error?) {
        self.dateRetrieved = Date()
        self.name = "--"
        self.currentPlanName = "--"
        self.numberOfBoardMeals = 0
        self.numberOfEquivalencyMeals = 0
        self.pointsInCents = 0
        self.catCashInCents = 0
        self.catCashBonusInCents = 0
        self.dateUpdated = nil
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

    /// The number of equivalency meals left.
    fileprivate let numberOfEquivalencyMeals: UInt

    /// The points left, stored in cents as an integer.
    /// Example: `"11.89" -> 1189`.
    fileprivate let pointsInCents: UInt

    /// The cat cash left, stored in cents as an integer.
    /// Example: `"11.89" -> 1189`.
    fileprivate let catCashInCents: UInt

    /// The cat cash bonus left, stored in cents as an integer.
    /// Example: `"11.89" -> 1189`.
    fileprivate let catCashBonusInCents: UInt

    /// The date parsed from the "Last Updated" field from the query, i.e., the date the data was updated serverside.
    /// Not to be confused with `dateRetrieved`.
    let dateUpdated: Date?

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
        aCoder.encode(numberOfEquivalencyMeals, forKey: "numberOfEquivalencyMeals")
        aCoder.encode(pointsInCents, forKey: "pointsInCents")
        aCoder.encode(catCashInCents, forKey: "catCashInCents")
        aCoder.encode(catCashBonusInCents, forKey: "catCashBonusInCents")
        if let dateUpdated = dateUpdated {
            aCoder.encode(dateUpdated, forKey: "dateUpdated")
        }
        if let errorValue = error?.rawValue {
            aCoder.encode(errorValue, forKey: "error")
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        self.dateRetrieved = aDecoder.decodeObject(forKey: "dateRetrieved") as! Date
        self.name = aDecoder.decodeObject(forKey: "name") as! String
        self.currentPlanName = aDecoder.decodeObject(forKey: "currentPlanName") as! String
        self.numberOfBoardMeals = aDecoder.decodeObject(forKey: "numberOfBoardMeals") as! UInt
        self.numberOfEquivalencyMeals = aDecoder.decodeObject(forKey: "numberOfEquivalencyMeals") as! UInt
        self.pointsInCents = aDecoder.decodeObject(forKey: "pointsInCents") as! UInt
        self.catCashInCents = aDecoder.decodeObject(forKey: "catCashInCents") as! UInt
        self.catCashBonusInCents = aDecoder.decodeObject(forKey: "catCashBonusInCents") as! UInt
        self.dateUpdated = aDecoder.decodeObject(forKey: "dateUpdated") as? Date
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

    /// The number of equivalency meals as a string.
    public var equivalencyMeals: String { return "\(numberOfEquivalencyMeals)" }

    /// Whether we should display the board meals description in plural form.
    private var equivalencyMealsIsPlural: Bool { return numberOfEquivalencyMeals != 1 }

    /// The description for 1 equivalency meal.
    private static var equivalencyMealSingularDescription: String { return "Equivalency" }

    /// The description for many equivalency meals.
    private static var equivalencyMealsPluralDescription: String { return "Equivalencies" }

    /// The pluralized/singular description for equivalency meals.
    var equivalencyMealsDescription: String { return equivalencyMealsIsPlural ? QueryResult.equivalencyMealsPluralDescription : QueryResult.equivalencyMealSingularDescription }

    /// The points as a string.
    public var points: String { return pointsInCents.centsToString() }

    /// The description for points.
    public var pointsDescription: String { return "Points" }

    /// The description for points, also available when the controller does not have a query result object.
    public static var pointsDescription: String { return "Points" }

    /// The Cat Cash and Cat Cash bonus added together.
    private var totalCatCashInCents: UInt { return catCashInCents + catCashBonusInCents }

    /// The total Cat Cash as a string.
    public var totalCatCash: String { return totalCatCashInCents.centsToString() }

    /// The description for Cat Cash.
    public var catCashDescription: String { return "Cat Cash" }

    /// The description for Cat Cash, also available when the controller does not have a query result object.
    public static var catCashDescription: String { return "Cat Cash" }

    /// Whether the user is on an unlimited meal plan or not.
    var isUnlimited: Bool {
        let match = try! currentPlanName.firstMatch(regexPattern: "Unlimited").first
        return match != nil
    }

    /// The date retrieved as a formatted string.
    public var dateRetrievedString: String { return MeowlWatchData.displayDateFormatter.string(from: dateRetrieved) }

    /// The date updated as a formatted string.
    public var dateUpdatedString: String? { return dateUpdated != nil ? MeowlWatchData.displayDateFormatter.string(from: dateUpdated!) : nil }

    /// The message to display if there is an error.
    public var errorString: String? {
        guard let error = error else { return nil }
        switch error {
        case .connectionError:
            return "Unable to connect to the server. Please make sure your device is connected to the internet."
        case .authenticationError:
            return "Unable to login to server. Please tap \"Account\" to make sure your NetID and password are correct."
        case .parseError:
            return "An unknown error has occurred. Please contact the developer of this app."
        }
    }


    /// An enum representing the each displayed item.
    public enum DisplayItem: Int {

        /// Board meals.
        case boardMeals

        /// Equivalency meals.
        case equivalencyMeals

        /// Points.
        case points

        /// Cat Cash.
        case catCash
        
    }

    /// The displayed description given an item type.
    /// - Parameter item: The display item type.
    /// - Returns: A string to display.
    private func description(forItem item: DisplayItem) -> String {
        switch item {
        case .boardMeals:
            return boardMealsDescription
        case .equivalencyMeals:
            return equivalencyMealsDescription
        case .points:
            return QueryResult.pointsDescription
        case .catCash:
            return QueryResult.catCashDescription
        }
    }

    /// The displayed description given an item type and a query result to pluralize it if needed.
    /// - Parameter item: The display item type.
    /// - Parameter query: A query result.
    /// - Returns: A string to display.
    public static func description(forItem item: DisplayItem, withQuery query: QueryResult?) -> String {
        switch item {
        case .boardMeals:
            return query?.description(forItem: .boardMeals) ?? boardMealsPluralDescription
        case .equivalencyMeals:
            return query?.description(forItem: .equivalencyMeals) ?? equivalencyMealsPluralDescription
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
    fileprivate func firstMatch(regexPattern: String) throws -> [String] {
        var strings: [String] = []
        let regex = try NSRegularExpression(pattern: regexPattern, options: [.dotMatchesLineSeparators, .caseInsensitive])
        let resultOptional = regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.characters.count))
        guard let result = resultOptional else { return [] }

        for index in 0..<result.numberOfRanges {
            let range = self.index(self.startIndex, offsetBy: result.rangeAt(index).location)..<self.index(self.startIndex, offsetBy: result.rangeAt(index).location + result.rangeAt(index).length)
            let string = self.substring(with: range)
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

        let wholeComponent = UInt(matches[1])! * 100
        let fractionalComponent = UInt(matches[2])!
        self = wholeComponent + fractionalComponent
    }

    /// Converts `self` into a two-decimal-place string representation.
    /// Example: `4245 -> "42.45"`.
    /// - Returns: The two-decimal-string representation.
    fileprivate func centsToString() -> String {
        let fractionalComponent = self % 100
        let fractionalString: String
        if fractionalComponent < 10 {
            fractionalString = "0\(fractionalComponent)"
        } else if fractionalComponent % 10 == 0 {
            fractionalString = "\(fractionalComponent)0"
        } else {
            fractionalString = "\(fractionalComponent)"
        }
        return "\(self / 100).\(fractionalString)"
    }
    
}
