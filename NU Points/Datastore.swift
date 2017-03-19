//
//  Datastore.swift
//  NU Points
//
//  Created by Jonathan Chan on 2017-03-17.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import Foundation

struct Datastore {

    private init() {}

    static var canQuery: Bool { return username != nil && password != nil }

    static var username: String? {
        get {
            return _username
        }
        set {
            _username = newValue
        }
    }
    private static var _username: String? = ""

    static var password: String? {
        get {
            return _password
        }
        set {
            _password = newValue
        }
    }
    private static var _password: String? = ""

    static let url: URL = URL(string: "https://go.dosa.northwestern.edu/uhfs/foodservice/balancecheck")!

    static func query(onCompletion: @escaping (QueryResult?) -> Void) {
        print("Querying...")

        let credentialsString = "\(username!):\(password!)"
        let credentialsData = credentialsString.data(using: .utf8)!
        let credentialsEncodedBase64 = credentialsData.base64EncodedString()
        let authorizationString = "Basic \(credentialsEncodedBase64)"
        var request = URLRequest(url: url)
        request.setValue(authorizationString, forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            print("Query finished.")

            guard let response = response as? HTTPURLResponse, let data = data else { return onCompletion(nil) }

            if response.statusCode != 200 { return onCompletion(nil) }

            let html = String(data: data, encoding: .utf8)!

            let result = QueryResult(html: html)
            self.lastQuery = result

            onCompletion(result)
        }

        task.resume()
    }

    static var lastQuery: QueryResult?

    static var displayDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E MMM d, h:mm a"
        return dateFormatter
    }()

}

class QueryResult: NSObject, NSCoding {

    init?(html: String) {
        self.dateRetrieved = Date()

        let contentString: String
        let matches: [String]

        do {
            contentString = try html.firstMatch(regexPattern: "<!--startindex-->.*<!--stopindex-->").first!
            matches = try contentString.firstMatch(regexPattern: "<td.*Name:.*</td>.*<td>([A-Za-z ]*)</td>.*<td.*Current Plan:.*</td>.*<td>([A-Za-z\\d ]*)</td>.*<td.*Board Meals:.*</td>.*<td>(\\d*)</td>.*<td.*Equivalency Meals:.*</td>.*<td>(\\d*)</td>.*<td.*Points:.*</td>.*<td>(\\d*.\\d{2})</td>.*<td.*Cat Cash:.*</td>.*<td>(\\d*.\\d{2})</td>.*<td.*Cat Cash Bonus:.*</td>.*<td>(\\d*.\\d{2})</td>.*Last Updated ([A-Za-z\\d,: ]*)")
        } catch { return nil }

        if matches.count != 9 { return nil }

        self.name = matches[1]
        self.currentPlanName = matches[2]
        self.numberOfBoardMeals = UInt(matches[3])!
        self.numberOfEquivalencyMeals = UInt(matches[4])!
        self.pointsInCents = UInt(toCentsWithString: matches[5])!
        self.catCashInCents = UInt(toCentsWithString: matches[6])!
        self.catCashBonusInCents = UInt(toCentsWithString: matches[7])!

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d, yyyy hh:mm a"
        self.dateUpdated = dateFormatter.date(from: matches[8])

        self.error = nil
    }

    override convenience init() {
        self.init(error: nil)
    }

    init(error: Error?) {
        self.dateRetrieved = Date()
        self.name = ""
        self.currentPlanName = ""
        self.numberOfBoardMeals = 0
        self.numberOfEquivalencyMeals = 0
        self.pointsInCents = 0
        self.catCashInCents = 0
        self.catCashBonusInCents = 0
        self.dateUpdated = nil
        self.error = error
    }

    let dateRetrieved: Date
    let name: String
    let currentPlanName: String

    fileprivate let numberOfBoardMeals: UInt
    fileprivate let numberOfEquivalencyMeals: UInt
    fileprivate let pointsInCents: UInt
    fileprivate let catCashInCents: UInt
    fileprivate let catCashBonusInCents: UInt

    let dateUpdated: Date?

    enum Error: UInt {
        case connectionError = 0
        case authenticationError
        case parseError
    }

    let error: Error?

    func encode(with aCoder: NSCoder) {
        aCoder.encode(dateRetrieved, forKey: "dateRetrieved")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(currentPlanName, forKey: "currentPlanName")
        aCoder.encode(numberOfBoardMeals, forKey: "numberOfBoardMeals")
        aCoder.encode(numberOfEquivalencyMeals, forKey: "numberOfEquivalencyMeals")
        aCoder.encode(pointsInCents, forKey: "pointsInCents")
        aCoder.encode(catCashInCents, forKey: "catCashInCents")
        aCoder.encode(catCashBonusInCents, forKey: "catCashBonusInCents")
        aCoder.encode(dateUpdated, forKey: "dateUpdated")
        aCoder.encode(error, forKey: "error")
    }

    required init?(coder aDecoder: NSCoder) {
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

    var boardMeals: String { return "\(numberOfBoardMeals)" }
    var equivalencyMeals: String { return "\(numberOfEquivalencyMeals)" }
    var points: String { return pointsInCents.centsToString() }
    var totalCatCashInCents: UInt { return catCashInCents + catCashBonusInCents }
    var totalCatCash: String { return totalCatCashInCents.centsToString() }

    var isUnlimited: Bool {
        let match = try! currentPlanName.firstMatch(regexPattern: "Unlimited").first
        return match != nil
    }

    var dateRetrievedString: String { return Datastore.displayDateFormatter.string(from: dateRetrieved) }
    var dateUpdatedString: String? { return dateUpdated != nil ? Datastore.displayDateFormatter.string(from: dateUpdated!) : nil }

}

extension String {

    func firstMatch(regexPattern: String) throws -> [String] {
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

    init?(toCentsWithString string: String) {
        let matches: [String]
        do {
            matches = try string.firstMatch(regexPattern: "(\\d*).(\\d{2})")
        } catch { return nil }

        if matches.count != 3 { return nil }

        let wholeComponent = UInt(matches[1])! * 100
        let fractionalComponent = UInt(matches[2])!
        self = wholeComponent + fractionalComponent
    }

    func centsToString() -> String {
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
