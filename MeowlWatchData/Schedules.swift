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

private let diningHalls: [DiningHall] = [.allison, .elder, .plexEast, .plexWest, .hinman, .sargent]

/// An enum representing each cafe or C-Store.
public enum CafeOrCStore: String {

    case plex = "Plex C-Store"

    case hinmanCStore = "Hinman C-Store"

    case frans = "Fran's Café at Hinman"

    case kresge = "Kresge Café"

    case einstein = "Einstein at Pancoe"

    case bergson = "Café Bergson"

    case techExpress = "Tech Express"

    case lisas = "Lisa's Café at Slivka"

}

private let cafesAndCStores: [CafeOrCStore] = [.plex, .hinmanCStore, .frans, .kresge, .einstein, .bergson, .techExpress, .lisas]

/// An enum representing each location at Norris.
public enum NorrisLocation: String {

    case internationalStation = "International Station"

    case catShack = "Cat Shack"

    case wildcatDen = "Wildcat Den"

    case northshorePizza = "Northshore Pizza"

    case pawsNGo = "Paws 'n' Go C-Store"

    case subway = "Subway"

    case starbucks = "Norbucks"

    case dunkinDonuts = "Dunkin' Donuts"

    case frontera = "Frontera"

}

private let norrisLocations: [NorrisLocation] = [.internationalStation, .catShack, .wildcatDen, .northshorePizza, .pawsNGo, .subway, .starbucks, .dunkinDonuts, .frontera]

/// An enum representing the status of dining locations.
public enum DiningStatus: String {

    case open = "Open"

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
let diningCalendar: Calendar = { () -> Calendar in
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

/// An object representing a schedule entry with a starting day of week, ending day of week, and array of time-status pairs during those specified days.
public struct ScheduleEntry<Status> where Status : RawRepresentable, Status.RawValue == String {

    // 1 = Sunday, 2 = Monday, etc.

    public let startingDayOfWeek: Int
    public let endingDayOfWeek: Int
    public let schedule: [(time: Int, status: Status)]

    /// Initializes an object with the schedule already sorted.
    fileprivate init?(dictionaryEntry dictionary: [String : Any]) {
        guard let startingDayOfWeek = dayOfWeek(string: dictionary[plistKeyForStartingDayOfWeek] as? String),
            let endingDayOfWeek = dayOfWeek(string: dictionary[plistKeyForEndingDayOfWeek] as? String),
            let scheduleRows = dictionary[plistKeyForSchedule] as? [String : String]
            else { return nil }

        self.startingDayOfWeek = startingDayOfWeek
        self.endingDayOfWeek = endingDayOfWeek

        var schedule: [(time: Int, status: Status)] = []

        for row in scheduleRows {
            guard let intKey = Int(row.key),
                let value = Status(rawValue: row.value) else { return nil }
            schedule.append((intKey, value))
        }
        schedule = schedule.sorted { (pair1, pair2) -> Bool in
            return pair1.time < pair2.time
        }

        self.schedule = schedule
    }

    public var formattedWeekdayRange: String {
        if startingDayOfWeek != endingDayOfWeek {
            return "\(dayOfWeekString(startingDayOfWeek)!) – \(dayOfWeekString(endingDayOfWeek)!)"
        } else {
            return "\(dayOfWeekString(startingDayOfWeek)!)"
        }
    }

    private func formattedTime(twentyFourHourTime: Int) -> String {
        let beforeNoon = twentyFourHourTime < 1200
        let hour = beforeNoon ? (twentyFourHourTime == 0 ? "12" : "\(twentyFourHourTime / 100)") : (twentyFourHourTime == 1200 || twentyFourHourTime == 2400 ? "12" : "\(twentyFourHourTime / 100 - 12)")
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

/// A dictionary of dictionaries of arrays of `ScheduleEntry`s.
/// `scheduleEntriesDictionaryDictionary[plistName][locationName]
private let diningHallScheduleEntriesDictionaryDictionary: [String : [String : [ScheduleEntry<DiningStatus>]]] = { () -> [String : [String : [ScheduleEntry<DiningStatus>]]] in
    let plistNames = [
        plistNameForDiningHallSchedules,
        plistNameForCafeOrCStoreSchedules,
        plistNameForNorrisLocationSchedules
    ]
    var diningHallScheduleEntriesDictionaryDictionary: [String : [String : [ScheduleEntry<DiningStatus>]]] = [:]
    for plistName in plistNames {
        let path = Bundle.main.path(forResource: plistName, ofType: "plist")!
        let dictionary = NSDictionary(contentsOfFile: path)! as! [String : Any] // [String : [String : [String : Any]]]; dictionary[locationName][arrayIndex][entryKey]
        diningHallScheduleEntriesDictionaryDictionary[plistName] = [:]
        for locationName in dictionary.keys {
            var entries: [ScheduleEntry<DiningStatus>] = []
            for dictionaryEntry in dictionary[locationName] as! [[String : Any]] {
                // Sorted already
                entries.append(ScheduleEntry(dictionaryEntry: dictionaryEntry)!)
            }

            diningHallScheduleEntriesDictionaryDictionary[plistName]![locationName] = entries
        }
    }
    return diningHallScheduleEntriesDictionaryDictionary
}()

private let plistNameForDiningHallSchedules = "DiningHallSchedules"
private let plistNameForCafeOrCStoreSchedules = "CafeSchedules"
private let plistNameForNorrisLocationSchedules = "NorrisSchedules"
private let plistNameForEquivalencySchedules = "EquivalencySchedules"

private func diningHallScheduleDictionaryFromPlist(_ fileName: String) -> [String : [ScheduleEntry<DiningStatus>]] {
    return diningHallScheduleEntriesDictionaryDictionary[fileName]!
}

public func diningHallScheduleEntries(for diningHall: DiningHall) -> [ScheduleEntry<DiningStatus>] {
    return diningHallScheduleDictionaryFromPlist(plistNameForDiningHallSchedules)[diningHall.rawValue]!
}

private func plistName<Key>(for keyType: Key.Type) -> String? where Key : RawRepresentable, Key.RawValue == String {
    if keyType == DiningHall.self {
        return plistNameForDiningHallSchedules
    }
    if keyType == CafeOrCStore.self {
        return plistNameForCafeOrCStoreSchedules
    }
    if keyType == NorrisLocation.self {
        return plistNameForNorrisLocationSchedules
    }
    if keyType == EquivalencyPeriod.self {
        return plistNameForEquivalencySchedules
    }
    return nil
}

private func diningStatus<Key>(for key: Key, at date: Date) -> DiningStatus where Key : RawRepresentable, Key.RawValue == String {
    let entries = diningHallScheduleDictionaryFromPlist(plistName(for: Key.self)!)[key.rawValue]!

    let dateAtStartOfDay = diningCalendar.startOfDay(for: date)
    let dayOfWeek = diningCalendar.component(.weekday, from: dateAtStartOfDay)

    for entry in entries {
        if dayOfWeek >= entry.startingDayOfWeek && dayOfWeek <= entry.endingDayOfWeek {
            let scheduleToday = entry.schedule
            for scheduleRow in scheduleToday {
                if date.twentyFourHourTime < scheduleRow.time {
                    return scheduleRow.status
                }
            }
        }
    }

    return .closed // default
}

private func diningStatuses<Key>(at date: Date) -> [(key: Key, status: DiningStatus)] where Key : RawRepresentable, Key.RawValue == String {
    guard let plistName = plistName(for: Key.self) else { return [] }
    return diningHallScheduleDictionaryFromPlist(plistName).keys.flatMap { locationName -> (key: Key, status: DiningStatus)? in
        let diningStatus = MeowlWatchData.diningStatus(for: Key(rawValue: locationName)!, at: date)
        return (key: Key(rawValue: locationName)!, status: diningStatus)
    }
    .sorted { (pair1, pair2) -> Bool in
        return pair1.key.rawValue < pair2.key.rawValue || pair1.status != .closed && pair2.status == .closed
    }
}

/// - Returns: An array of dining hall-status pairs sorted by the status at the given date.
public func diningHallStatuses(at date: Date) -> [(key: DiningHall, status: DiningStatus)] {
    return diningStatuses(at: date)
}

public func diningHallStatus(for diningHall: DiningHall, at date: Date) -> DiningStatus {
    return diningStatus(for: diningHall, at: date)
}

public func indexPathOfDiningHallScheduleEntries(for diningHall: DiningHall, at date: Date) -> IndexPath {
    let dayOfWeek = diningCalendar.component(.weekday, from: date)
    let entries = diningHallScheduleEntries(for: diningHall)
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

public func cafeOrCStoreScheduleEntries(for cafeOrCStore: CafeOrCStore) -> [ScheduleEntry<DiningStatus>] {
    return diningHallScheduleDictionaryFromPlist(plistName(for: type(of: cafeOrCStore))!)[cafeOrCStore.rawValue]!
}

public func cafeOrCStoreStatus(_ cafeOrCStore: CafeOrCStore, at date: Date) -> DiningStatus {
    return diningStatus(for: cafeOrCStore, at: date)
}

public func cafesAndCStoreStatuses(at date: Date) -> [(key: CafeOrCStore, status: DiningStatus)] {
    return diningStatuses(at: date)
}

public func indexPathOfCafeOrCStoreEntries(for cafeOrCStore: CafeOrCStore, at date: Date) -> IndexPath {
    let dayOfWeek = diningCalendar.component(.weekday, from: date)
    let entries = cafeOrCStoreScheduleEntries(for: cafeOrCStore)
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

public func norrisLocationScheduleEntries(for norrisLocation: NorrisLocation) -> [ScheduleEntry<DiningStatus>] {
    return diningHallScheduleDictionaryFromPlist(plistName(for: type(of: norrisLocation))!)[norrisLocation.rawValue]!
}

public func norrisLocationStatus(_ norrisLocation: NorrisLocation, at date: Date) -> DiningStatus {
    return diningStatus(for: norrisLocation, at: date)
}

public func norrisLocationStatuses(at date: Date) -> [(key: NorrisLocation, status: DiningStatus)] {
    return diningStatuses(at: date)
}

public func indexPathOfNorrisLocationScheduleEntries(for norrisLocation: NorrisLocation, at date: Date) -> IndexPath {
    let dayOfWeek = diningCalendar.component(.weekday, from: date)
    let entries = norrisLocationScheduleEntries(for: norrisLocation)
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

    let scheduleEntries = equivalencyScheduleEntries

    let dateAtStartOfDay = diningCalendar.startOfDay(for: date)
    let dayOfWeek = diningCalendar.component(.weekday, from: dateAtStartOfDay)

    for entry in scheduleEntries {
        if dayOfWeek >= entry.startingDayOfWeek && dayOfWeek <= entry.endingDayOfWeek {
            let scheduleToday = entry.schedule
            for scheduleRow in scheduleToday {
                if date.twentyFourHourTime < scheduleRow.time {
                    return scheduleRow.status
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

public let equivalencyScheduleEntries: [ScheduleEntry<EquivalencyPeriod>] = {
    let path = Bundle.main.path(forResource: plistNameForEquivalencySchedules, ofType: "plist")!
    let diningHallDictionaryEntries = NSArray(contentsOfFile: path) as! [[String : Any]]
    var scheduleEntries: [ScheduleEntry<EquivalencyPeriod>] = []
    for dictionaryEntry in diningHallDictionaryEntries {
        scheduleEntries.append(ScheduleEntry(dictionaryEntry: dictionaryEntry)!)
    }
    return scheduleEntries
}()

public func indexPathOfEquivalencyScheduleEntries(at date: Date) -> IndexPath {
    let dayOfWeek = diningCalendar.component(.weekday, from: date)
    let entries = equivalencyScheduleEntries
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
