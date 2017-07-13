//
//  Schedules.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-04-30.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import Foundation

// TODO: Change after summer
private let plistNameForDiningHallSchedules = "DiningHallSchedules-Summer"
private let plistNameForCafeOrCStoreSchedules = "CafeSchedules-Summer"
private let plistNameForNorrisLocationSchedules = "NorrisSchedules-Summer"

// Root is an array
private let plistNameForEquivalencySchedules = "EquivalencySchedules"

/// An enum representing each dining hall.
public enum DiningHall: String {

    case allison = "Allison"

    case elder = "Elder"

    case plexEast = "Plex East"

    case plexWest = "Plex West"

    case hinman = "Hinman"

    case sargent = "Sargent"
    
}

public let diningHalls: [DiningHall] = [.allison, .elder, .plexEast, .plexWest, .hinman, .sargent]

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

public let cafesAndCStores: [CafeOrCStore] = [.plex, .hinmanCStore, .frans, .kresge, .einstein, .bergson, .techExpress, .lisas]

/// An enum representing each location at Norris.
public enum NorrisLocation: String {

    case internationalStation = "International Station"

    case catShack = "Cat Shack"

    case wildcatDen = "Shakespeare Garden"

    case northshorePizza = "Northshore Pizza"

    case pawsNGo = "Paws 'n' Go C-Store"

    case subway = "Subway"

    case starbucks = "Norbucks"

    case dunkinDonuts = "Dunkin' Donuts"

    case frontera = "Frontera"

}

public let norrisLocations: [NorrisLocation] = [.internationalStation, .catShack, .wildcatDen, .northshorePizza, .pawsNGo, .subway, .starbucks, .dunkinDonuts, .frontera]

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

private func dayOfWeekString(_ int: Int) -> String? {
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

/// An object representing a row in the schedule, with a starting time, an ending time, and a status
public struct ScheduleRow<Status> where Status : RawRepresentable, Status.RawValue == String {

    public let status: Status

    public let startingTime: Int
    public let endingTime: Int

    fileprivate init(status: Status, startingTime: Int, endingTime: Int) {
        self.status = status
        self.startingTime = startingTime
        self.endingTime = endingTime
    }

    private func formattedTime(twentyFourHourTime: Int) -> String {
        if twentyFourHourTime == 2400 { return "12:00 AM" }
        let beforeNoon = twentyFourHourTime < 1200
        let hour = beforeNoon ? (twentyFourHourTime == 0 ? "12" : "\(twentyFourHourTime / 100)") : (twentyFourHourTime == 1200 ? "12" : "\(twentyFourHourTime / 100 - 12)")
        let minute = twentyFourHourTime % 100 < 10 ? "0\(twentyFourHourTime % 100)" : "\(twentyFourHourTime % 100)"
        let amOrPm = beforeNoon ? "AM" : "PM"
        return "\(hour):\(minute) \(amOrPm)"
    }

    public var formattedTimeRange: String? {
        if startingTime == 0 && endingTime == 2400 { return "All Day" }
        return "\(formattedTime(twentyFourHourTime: startingTime)) – \(formattedTime(twentyFourHourTime: endingTime))"
    }
    
}

/// An object representing a schedule entry with a starting day of week, ending day of week, and array of time-status pairs during those specified days.
/// The `Status` is the status of what we're representing, like the status of a dining hall or the equivalency exchange rate.
public struct ScheduleEntry<Status> where Status : RawRepresentable, Status.RawValue == String {

    // 1 = Sunday, 2 = Monday, etc.

    public let startingDayOfWeek: Int
    public let endingDayOfWeek: Int
    public let schedule: [ScheduleRow<Status>]

    /// Initializes an object with the schedule already sorted.
    fileprivate init?(dictionaryEntry dictionary: [String : Any]) {
        guard let startingDayOfWeek = dayOfWeek(string: dictionary[plistKeyForStartingDayOfWeek] as? String),
            let endingDayOfWeek = dayOfWeek(string: dictionary[plistKeyForEndingDayOfWeek] as? String),
            let scheduleDictionary = dictionary[plistKeyForSchedule] as? [String : String]
            else { return nil }

        self.startingDayOfWeek = startingDayOfWeek
        self.endingDayOfWeek = endingDayOfWeek

        var scheduleArray: [(time: Int, status: Status)] = []

        for row in scheduleDictionary {
            guard let intKey = Int(row.key),
                let value = Status(rawValue: row.value) else { return nil }
            scheduleArray.append((intKey, value))
        }
        scheduleArray = scheduleArray.sorted { (pair1, pair2) -> Bool in
            return pair1.time < pair2.time
        }

        var schedule: [ScheduleRow<Status>] = []

        for i in 0..<scheduleArray.count {
            let status = scheduleArray[i].status
            let startingTime = i != 0 ? scheduleArray[i - 1].time : 0
            let endingTime = scheduleArray[i].time

            schedule.append(ScheduleRow(status: status, startingTime: startingTime, endingTime: endingTime))
        }

        self.schedule = schedule
    }

    public var formattedWeekdayRange: String {
        if startingDayOfWeek != endingDayOfWeek {
            if startingDayOfWeek == 1 && endingDayOfWeek == 7 {
                return "Every Day"
            }
            return "\(dayOfWeekString(startingDayOfWeek)!) – \(dayOfWeekString(endingDayOfWeek)!)"
        } else {
            return "\(dayOfWeekString(startingDayOfWeek)!)"
        }
    }

    fileprivate let plistKeyForStartingDayOfWeek = "StartingDayOfWeek"
    fileprivate let plistKeyForEndingDayOfWeek = "EndingDayOfWeek"
    fileprivate let plistKeyForSchedule = "Schedule"

    public func formattedTimeRange(atIndex index: Int) -> String? {
        return schedule[index].formattedTimeRange
    }

    fileprivate init(from original: ScheduleEntry<Status>, withScheduleFilteredBy scheduleRowIsIncluded: ((ScheduleRow<Status>) -> Bool)) {
        self.startingDayOfWeek = original.startingDayOfWeek
        self.endingDayOfWeek = original.endingDayOfWeek

        self.schedule = original.schedule.filter(scheduleRowIsIncluded)
    }

}

/// A dictionary of dictionaries of arrays of `ScheduleEntry`s.
/// `scheduleEntriesDictionaryDictionary[plistName][locationName]`
private let diningScheduleEntriesDictionaryDictionary: [String : [String : [ScheduleEntry<DiningStatus>]]] = { () -> [String : [String : [ScheduleEntry<DiningStatus>]]] in
    let plistNames = [
        plistNameForDiningHallSchedules,
        plistNameForCafeOrCStoreSchedules,
        plistNameForNorrisLocationSchedules
    ]
    var diningScheduleEntriesDictionaryDictionary: [String : [String : [ScheduleEntry<DiningStatus>]]] = [:]
    for plistName in plistNames {
        let path = Bundle.main.path(forResource: plistName, ofType: "plist")!
        let dictionary = NSDictionary(contentsOfFile: path)! as! [String : Any] // [String : [String : [String : Any]]]; dictionary[locationName][arrayIndex][entryKey]
        diningScheduleEntriesDictionaryDictionary[plistName] = [:]
        for locationName in dictionary.keys {
            var entries: [ScheduleEntry<DiningStatus>] = []
            for dictionaryEntry in dictionary[locationName] as! [[String : Any]] {
                // Sorted already
                entries.append(ScheduleEntry(dictionaryEntry: dictionaryEntry)!)
            }

            diningScheduleEntriesDictionaryDictionary[plistName]![locationName] = entries
        }
    }
    return diningScheduleEntriesDictionaryDictionary
}()

private let diningScheduleEntriesFilteredByNotClosedDictionaryDictionary: [String : [String : [ScheduleEntry<DiningStatus>]]] = { () -> [String : [String : [ScheduleEntry<DiningStatus>]]] in
    var diningScheduleEntriesFilteredByNotClosedDictionaryDictionary: [String : [String : [ScheduleEntry<DiningStatus>]]] = [:]

    for plistPair in diningScheduleEntriesDictionaryDictionary {
        diningScheduleEntriesFilteredByNotClosedDictionaryDictionary[plistPair.key] = [:]
        for diningLocationPair in plistPair.value {
            diningScheduleEntriesFilteredByNotClosedDictionaryDictionary[plistPair.key]![diningLocationPair.key] = []
            for entry in diningLocationPair.value {
                let newEntry: ScheduleEntry<DiningStatus>
                if entry.schedule.count == 1 {
                    newEntry = entry
                } // in case it's open or closed all day
                else {
                    newEntry = ScheduleEntry(from: entry, withScheduleFilteredBy: { scheduleRow -> Bool in
                        return scheduleRow.status != .closed
                    })
                }
                diningScheduleEntriesFilteredByNotClosedDictionaryDictionary[plistPair.key]![diningLocationPair.key]!.append(newEntry)
            }
        }
    }

    return diningScheduleEntriesFilteredByNotClosedDictionaryDictionary
}()

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

/// For a single dining location
public func diningStatus<DiningLocation>(for diningLocation: DiningLocation, at date: Date) -> DiningStatus where DiningLocation : RawRepresentable, DiningLocation.RawValue == String {
    let defaultValue = DiningStatus.closed

    guard let plistName = MeowlWatchData.plistName(for: DiningLocation.self),
        let entries = diningScheduleDictionaryFromPlist(plistName)[diningLocation.rawValue]
        else { return defaultValue }

    let dateAtStartOfDay = diningCalendar.startOfDay(for: date)
    let dayOfWeek = diningCalendar.component(.weekday, from: dateAtStartOfDay)

    for entry in entries {
        if dayOfWeek >= entry.startingDayOfWeek && dayOfWeek <= entry.endingDayOfWeek {
            let scheduleToday = entry.schedule
            for scheduleRow in scheduleToday {
                if date.twentyFourHourTime >= scheduleRow.startingTime && date.twentyFourHourTime < scheduleRow.endingTime {
                    return scheduleRow.status
                }
            }
        }
    }

    return defaultValue // default
}

/// For a list of dining locations, like for in the master VC.
public func diningStatuses<DiningLocation>(at date: Date) -> [(key: DiningLocation, status: DiningStatus)] where DiningLocation : RawRepresentable, DiningLocation.RawValue == String {
    guard let plistName = plistName(for: DiningLocation.self) else { return [] }
    return diningScheduleDictionaryFromPlist(plistName).keys.flatMap { locationName -> (key: DiningLocation, status: DiningStatus)? in
        let diningStatus = MeowlWatchData.diningStatus(for: DiningLocation(rawValue: locationName)!, at: date)
        return (key: DiningLocation(rawValue: locationName)!, status: diningStatus)
    }
    .sorted { (pair1, pair2) -> Bool in // Sorted by open > closed first, and then by alphabet
        if pair1.status != pair2.status { return pair1.status != .closed }
        return pair1.key.rawValue < pair2.key.rawValue
    }
}

/// A filtered list of schedule entries for use in the detail VC
public func openDiningScheduleEntries<DiningLocation>(for diningLocation: DiningLocation) -> [ScheduleEntry<DiningStatus>] where DiningLocation : RawRepresentable, DiningLocation.RawValue == String {
    guard let plistName = MeowlWatchData.plistName(for: DiningLocation.self),
        let dictionary = diningScheduleEntriesFilteredByNotClosedDictionaryDictionary[plistName],
        let entries = dictionary[diningLocation.rawValue]
        else { return [] }
    return entries
}

/// For selecting the current index path
public func indexPathOfOpenDiningScheduleEntries<DiningLocation>(for diningHall: DiningLocation, at date: Date) -> (row: Int?, section: Int) where DiningLocation : RawRepresentable, DiningLocation.RawValue == String {
    let dayOfWeek = diningCalendar.component(.weekday, from: date)
    let hour = diningCalendar.component(.hour, from: date)
    let entries = openDiningScheduleEntries(for: diningHall)
    var row: Int?
    var section: Int = 0
    for i in 0..<entries.count {
        let entry = entries[i]
        if dayOfWeek >= entry.startingDayOfWeek && dayOfWeek <= entry.endingDayOfWeek || entry.startingDayOfWeek == 7 && entry.endingDayOfWeek == 1 && (dayOfWeek == 1 || dayOfWeek == 7) {
            let scheduleToday = entry.schedule
            var isAfterHoursOfEndingDayOfWeek = false
            for j in 0..<scheduleToday.count {
                if date.twentyFourHourTime >= scheduleToday[j].startingTime && date.twentyFourHourTime < scheduleToday[j].endingTime {
                    row = j
                    section = i
                    break
                }
                if dayOfWeek == entry.endingDayOfWeek && j == scheduleToday.count - 1 && hour >= 18 { isAfterHoursOfEndingDayOfWeek = true } // day matches but looped to the last row of the day and no match; therefore it's after the last open entry of the day and we should go to the next day
            }
            // in day range but time range not found; default to the next section if it's at the end of the date range
            section = isAfterHoursOfEndingDayOfWeek ? (i + 1) % entries.count : i
            break
        }
    }
    return (row: row, section: section)
}

private func diningScheduleDictionaryFromPlist(_ fileName: String) -> [String : [ScheduleEntry<DiningStatus>]] {
    return diningScheduleEntriesDictionaryDictionary[fileName]!
}

/// MARK: - Equivalencies

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
                if date.twentyFourHourTime < scheduleRow.endingTime {
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

private let equivalencyScheduleEntries: [ScheduleEntry<EquivalencyPeriod>] = {
    let path = Bundle.main.path(forResource: plistNameForEquivalencySchedules, ofType: "plist")!
    let diningHallDictionaryEntries = NSArray(contentsOfFile: path) as! [[String : Any]]
    var scheduleEntries: [ScheduleEntry<EquivalencyPeriod>] = []
    for dictionaryEntry in diningHallDictionaryEntries {
        scheduleEntries.append(ScheduleEntry(dictionaryEntry: dictionaryEntry)!)
    }
    return scheduleEntries
}()

public let openEquivalencyScheduleEntries: [ScheduleEntry<EquivalencyPeriod>] = {
    var newEntries: [ScheduleEntry<EquivalencyPeriod>] = []
    for entry in equivalencyScheduleEntries {
        newEntries.append(ScheduleEntry(from: entry, withScheduleFilteredBy: { row -> Bool in
            return row.status != .unavailable
        }))
    }
    return newEntries
}()

public func indexPathOfEquivalencyScheduleEntries(at date: Date) -> (row: Int?, section: Int) {
    let dayOfWeek = diningCalendar.component(.weekday, from: date)
    let hour = diningCalendar.component(.hour, from: date)
    let entries = openEquivalencyScheduleEntries
    var row: Int?
    var section: Int = 0
    for i in 0..<entries.count {
        let entry = entries[i]
        if dayOfWeek >= entry.startingDayOfWeek && dayOfWeek <= entry.endingDayOfWeek || entry.startingDayOfWeek == 7 && entry.endingDayOfWeek == 1 && (dayOfWeek == 1 || dayOfWeek == 7) {
            let scheduleToday = entry.schedule
            var isAfterHoursOfEndingDayOfWeek = false
            for j in 0..<scheduleToday.count {
                if date.twentyFourHourTime >= scheduleToday[j].startingTime && date.twentyFourHourTime < scheduleToday[j].endingTime {
                    row = j
                    section = i
                    break
                }
                if dayOfWeek == entry.endingDayOfWeek && j == scheduleToday.count - 1 && hour >= 18 { isAfterHoursOfEndingDayOfWeek = true } // day matches but looped to the last row of the day and no match; therefore it's after the last open entry of the day and we should go to the next day
            }
            // in day range but time range not found; default to the next section if it's at the end of the date range
            section = isAfterHoursOfEndingDayOfWeek ? (i + 1) % entries.count : i
            break
        }
    }
    return (row: row, section: section)
}

public let scheduleDisclaimerString = "Schedules displayed are for Summer Quarter only, and may differ.\n\nWeekly plans reset on Sundays at 7 AM Central Time."
