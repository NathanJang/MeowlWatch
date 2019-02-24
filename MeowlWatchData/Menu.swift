//
//  Menu.swift
//  MeowlWatchData
//
//  Created by Jonathan Chan on 2019-02-08.
//  Copyright © 2019 Jonathan Chan. All rights reserved.
//

import Foundation
import Alamofire

struct MenuResponseBody: Codable {
    let menu: Menu
}

public struct Menu: Codable {

    public let periods: [Period]

    public struct Period: Codable {
        public let name: String
        public let categories: [Category]

        public var items: [Category.Item] {
            return categories.map { $0.items }.joined().map { $0 }
        }

        public struct Category: Codable {
            public let name: String
            public let items: [Item]

            public struct Item: Codable {
                public let name: String
                public let description: String?

                enum CodingKeys: String, CodingKey {
                    case name
                    case description = "desc"
                }
            }

        }
    }

}

public func getMenu(locationId: String, date: Date = Date(), completion: ((Menu?) -> Void)?) {
    let dateString: String = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-M-d"
        return dateFormatter.string(from: date)
    }()
    let urlString = "https://api.dineoncampus.com/v1/location/menu?site_id=5acea5d8f3eeb60b08c5a50d&platform=0&location_id=\(locationId)&date=\(dateString)"
    Alamofire.request(urlString).responseData { response in
        let data = response.result.value!
        let decoder = JSONDecoder()
        let response = try? decoder.decode(MenuResponseBody.self, from: data)
        completion?(response?.menu)
    }
}
