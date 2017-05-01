//
//  Schedules.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-04-30.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import Foundation

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

    case hinmanCStore = "Hinman C-Store"

    case frans = "Fran's Cafe at Hinman"

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

extension Date {
    fileprivate var twentyFourHourTime: Int {
        let hour = diningCalendar.component(.hour, from: self)
        let minute = diningCalendar.component(.minute, from: self)
        return 100 * hour + minute
    }
}

private func dayOfWeek(string: String?) -> Int? {
    guard let string = string else { return nil }
    switch string {
    case "Sunday":
        return 1
    case "Monday":
        return 2
    case "Tuesday":
        return 3
    case "Wednesday":
        return 4
    case "Thursday":
        return 5
    case "Friday":
        return 6
    case "Saturday":
        return 7
    default:
        return nil
    }
}

public func dayOfWeekString(_ int: Int) -> String? {
    switch int {
    case 1:
        return "Sunday"
    case 2:
        return "Monday"
    case 3:
        return "Tuesday"
    case 4:
        return "Wednesday"
    case 5:
        return "Thursday"
    case 6:
        return "Friday"
    case 7:
        return "Saturday"
    default:
        return nil
    }
}

private let plistKeyForStartingDayOfWeek = "StartingDayOfWeek"
private let plistKeyForEndingDayOfWeek = "EndingDayOfWeek"
private let plistKeyForSchedule = "Schedule"

public struct ScheduleEntry<State> {

    public let startingDayOfWeek: Int
    public let endingDayOfWeek: Int
    public let schedule: [(time: Int, state: State)]

    public var formattedWeekdayRange: String {
        if startingDayOfWeek != endingDayOfWeek {
            return "\(dayOfWeekString(startingDayOfWeek)!) – \(dayOfWeekString(endingDayOfWeek)!)"
        } else {
            return "\(dayOfWeekString(startingDayOfWeek)!)"
        }
    }

    private func formattedTime(twentyFourHourTime: Int) -> String {
        let beforeNoon = twentyFourHourTime < 1200
        let hour = beforeNoon ? (twentyFourHourTime == 0 ? "12" : "\(twentyFourHourTime / 100)") : (twentyFourHourTime == 2400 ? "12" : "\(twentyFourHourTime / 100 - 12)")
        let minute = twentyFourHourTime % 100 < 10 ? "0\(twentyFourHourTime % 100)" : "\(twentyFourHourTime % 100)"
        let amOrPm = beforeNoon ? "AM" : "PM"
        return "\(hour):\(minute) \(amOrPm)"
    }

    public func formattedTimeRange(atIndex index: Int) -> String? {
        guard index < schedule.count else { return nil }
        let lowerBound: Int
        if index == 0 {
            lowerBound = 0
        } else {
            lowerBound = schedule[index - 1].time
        }
        let upperBound = schedule[index].time % 100 == 0 ? schedule[index].time - 41 : schedule[index].time - 1
        return "\(formattedTime(twentyFourHourTime: lowerBound)) – \(formattedTime(twentyFourHourTime: upperBound))"
    }
}

extension ScheduleEntry where State == DiningHallSession {

    fileprivate init?(dictionaryEntry dictionary: [String : Any]) {
        guard let startingDayOfWeek = dayOfWeek(string: dictionary[plistKeyForStartingDayOfWeek] as? String),
            let endingDayOfWeek = dayOfWeek(string: dictionary[plistKeyForEndingDayOfWeek] as? String),
            let scheduleRows = dictionary[plistKeyForSchedule] as? [String : String]
            else { return nil }

        self.startingDayOfWeek = startingDayOfWeek
        self.endingDayOfWeek = endingDayOfWeek

        var schedule: [(time: Int, state: State)] = []

        for row in scheduleRows {
            guard let intKey = Int(row.key),
                let value = DiningHallSession(rawValue: row.value)
                else { return nil }
            schedule.append((intKey, value))
        }
        schedule = schedule.sorted { (pair1, pair2) -> Bool in
            return pair1.time < pair2.time
        }

        self.schedule = schedule
    }

}

extension ScheduleEntry where State == EquivalencyPeriod {

    fileprivate init?(dictionaryEntry dictionary: [String : Any]) {
        guard let startingDayOfWeek = dayOfWeek(string: dictionary[plistKeyForStartingDayOfWeek] as? String),
            let endingDayOfWeek = dayOfWeek(string: dictionary[plistKeyForEndingDayOfWeek] as? String),
            let scheduleRows = dictionary[plistKeyForSchedule] as? [String : String]
            else { return nil }

        self.startingDayOfWeek = startingDayOfWeek
        self.endingDayOfWeek = endingDayOfWeek

        var schedule: [(time: Int, state: State)] = []

        for row in scheduleRows {
            guard let intKey = Int(row.key),
                let value = EquivalencyPeriod(rawValue: row.value)
                else { return nil }
            schedule.append((intKey, value))
        }
        schedule = schedule.sorted { (pair1, pair2) -> Bool in
            return pair1.time < pair2.time
        }

        self.schedule = schedule
    }
    
}

extension ScheduleEntry where State == Bool {

    fileprivate init?(dictionaryEntry dictionary: [String : Any]) {
        guard let startingDayOfWeek = dayOfWeek(string: dictionary[plistKeyForStartingDayOfWeek] as? String),
            let endingDayOfWeek = dayOfWeek(string: dictionary[plistKeyForEndingDayOfWeek] as? String),
            let scheduleRows = dictionary[plistKeyForSchedule] as? [String : Bool]
            else { return nil }

        self.startingDayOfWeek = startingDayOfWeek
        self.endingDayOfWeek = endingDayOfWeek

        var schedule: [(time: Int, state: State)] = []

        for row in scheduleRows {
            guard let intKey = Int(row.key)
                else { return nil }
            schedule.append((intKey, row.value))
        }
        schedule = schedule.sorted { (pair1, pair2) -> Bool in
            return pair1.time < pair2.time
        }

        self.schedule = schedule
    }

}

private func dictionaryFromPlist(_ fileName: String) -> [String : Any]? {
    guard let path = Bundle.main.path(forResource: fileName, ofType: "plist", inDirectory: "Frameworks/MeowlWatchData.framework") else { return nil }
    return NSDictionary(contentsOfFile: path) as? [String : Any]
}

public func diningHallScheduleEntries(for diningHall: DiningHall) -> [ScheduleEntry<DiningHallSession>] {
    let diningHallDictionaryEntries = dictionaryFromPlist("DiningHallSchedules")![diningHall.rawValue] as! [[String : Any]]
    var scheduleEntries: [ScheduleEntry<DiningHallSession>] = []
    for dictionaryEntry in diningHallDictionaryEntries {
        scheduleEntries.append(ScheduleEntry(dictionaryEntry: dictionaryEntry)!)
    }
    return scheduleEntries
}

public func diningSession(for diningHall: DiningHall, at date: Date) -> DiningHallSession {
    let defaultValue = DiningHallSession.closed

    let scheduleEntries = diningHallScheduleEntries(for: diningHall)

    let dateAtStartOfDay = diningCalendar.startOfDay(for: date)
    let dayOfWeek = diningCalendar.component(.weekday, from: dateAtStartOfDay)

    for entry in scheduleEntries {
        if dayOfWeek >= entry.startingDayOfWeek && dayOfWeek <= entry.endingDayOfWeek {
            let scheduleToday = entry.schedule
            for scheduleRow in scheduleToday {
                if date.twentyFourHourTime < scheduleRow.time {
                    return scheduleRow.state
                }
            }
        }
    }

    return defaultValue
}

public func cafeOrCStoreScheduleEntries(for cafeOrCStore: CafeOrCStore) -> [ScheduleEntry<Bool>] {
    let diningHallDictionaryEntries = dictionaryFromPlist("CafeSchedules")![cafeOrCStore.rawValue] as! [[String : Any]]
    var scheduleEntries: [ScheduleEntry<Bool>] = []
    for dictionaryEntry in diningHallDictionaryEntries {
        scheduleEntries.append(ScheduleEntry(dictionaryEntry: dictionaryEntry)!)
    }
    return scheduleEntries
}

public func isOpen(_ cafeOrCStore: CafeOrCStore, at date: Date) -> Bool {
    let defaultValue = false

    let scheduleEntries = cafeOrCStoreScheduleEntries(for: cafeOrCStore)

    let dateAtStartOfDay = diningCalendar.startOfDay(for: date)
    let dayOfWeek = diningCalendar.component(.weekday, from: dateAtStartOfDay)

    for entry in scheduleEntries {
        if dayOfWeek >= entry.startingDayOfWeek && dayOfWeek <= entry.endingDayOfWeek {
            let scheduleToday = entry.schedule
            for scheduleRow in scheduleToday {
                if date.twentyFourHourTime < scheduleRow.time {
                    return scheduleRow.state
                }
            }
        }
    }

    return defaultValue
}

public func norrisLocationScheduleEntries(for norrisLocation: NorrisLocation) -> [ScheduleEntry<Bool>] {
    let diningHallDictionaryEntries = dictionaryFromPlist("NorrisSchedules")![norrisLocation.rawValue] as! [[String : Any]]
    var scheduleEntries: [ScheduleEntry<Bool>] = []
    for dictionaryEntry in diningHallDictionaryEntries {
        scheduleEntries.append(ScheduleEntry(dictionaryEntry: dictionaryEntry)!)
    }
    return scheduleEntries
}

public func isOpen(_ norrisLocation: NorrisLocation, at date: Date) -> Bool {
    let defaultValue = false

    let scheduleEntries = norrisLocationScheduleEntries(for: norrisLocation)

    let dateAtStartOfDay = diningCalendar.startOfDay(for: date)
    let dayOfWeek = diningCalendar.component(.weekday, from: dateAtStartOfDay)

    for entry in scheduleEntries {
        if dayOfWeek >= entry.startingDayOfWeek && dayOfWeek <= entry.endingDayOfWeek {
            let scheduleToday = entry.schedule
            for scheduleRow in scheduleToday {
                if date.twentyFourHourTime < scheduleRow.time {
                    return scheduleRow.state
                }
            }
        }
    }

    return defaultValue
}


/// An enum representing the different periods of equivalency exchanges.
public enum EquivalencyPeriod : String {

    case breakfast = "Breakfast"

    case lunch = "Lunch"

    case dinner = "Dinner"

    case lateNight = "Late Night"

    case unavailable = "Unavailable"

}

/// Returns the equivalency period for the current date, also accounting for time zone.
/// - Parameter date: The date to calculate from.
/// - Returns: The equivalency period.
private func equivalencyPeriod(at date: Date) -> EquivalencyPeriod {
    let defaultValue = EquivalencyPeriod.unavailable

    let scheduleEntries = equivalencyScheduleEntries()

    let dateAtStartOfDay = diningCalendar.startOfDay(for: date)
    let dayOfWeek = diningCalendar.component(.weekday, from: dateAtStartOfDay)

    for entry in scheduleEntries {
        if dayOfWeek >= entry.startingDayOfWeek && dayOfWeek <= entry.endingDayOfWeek {
            let scheduleToday = entry.schedule
            for scheduleRow in scheduleToday {
                if date.twentyFourHourTime < scheduleRow.time {
                    return scheduleRow.state
                }
            }
        }
    }

    return defaultValue
}

/// Returns the exchange rate string (with "$") given a date.
/// - Parameter date: The date to calculate from.
/// - Returns: The string (with "$"), or nil if unavailable.
public func equivalencyExchangeRateString(at date: Date) -> String {
    let period = equivalencyPeriod(at: date)
    return equivalencyExchangeRateString(for: period)
}

public func equivalencyExchangeRateString(for period: EquivalencyPeriod) -> String {
    switch period {
    case .breakfast:
        return "$5"
    case .lunch:
        return "$7"
    case .dinner:
        return "$9"
    case .lateNight:
        return "$7"
    case .unavailable:
        return "--"
    }
}

public func equivalencyScheduleEntries() -> [ScheduleEntry<EquivalencyPeriod>] {
    let path = Bundle.main.path(forResource: "EquivalencySchedules", ofType: "plist", inDirectory: "Frameworks/MeowlWatchData.framework")!
    let diningHallDictionaryEntries = NSArray(contentsOfFile: path) as! [[String : Any]]
    var scheduleEntries: [ScheduleEntry<EquivalencyPeriod>] = []
    for dictionaryEntry in diningHallDictionaryEntries {
        scheduleEntries.append(ScheduleEntry(dictionaryEntry: dictionaryEntry)!)
    }
    return scheduleEntries
}

public func indexPathOfScheduleEntries(at date: Date) -> IndexPath {
    let dayOfWeek = diningCalendar.component(.weekday, from: date)
    let entries = equivalencyScheduleEntries()
    var indexPath: IndexPath?
    for i in 0..<entries.count {
        let entry = entries[i]
        if dayOfWeek >= entry.startingDayOfWeek && dayOfWeek <= entry.endingDayOfWeek {
            let scheduleToday = entry.schedule
            for j in 0..<scheduleToday.count {
                if date.twentyFourHourTime < scheduleToday[j].time {
                    indexPath = IndexPath(row: j, section: i)
                    break
                }
            }
        }
    }
    return indexPath!
}
