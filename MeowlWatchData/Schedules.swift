//
//  Schedules.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-04-30.
//  Copyright © 2018 Jonathan Chan. All rights reserved.
//

import Foundation

private let plistNameForDiningHallSchedules = "DiningHallSchedules"
private let plistNameForCafeOrCStoreSchedules = "CafeSchedules"
private let plistNameForNorrisLocationSchedules = "NorrisSchedules"

/// An enum representing each dining hall.
public enum DiningHall: String {

    case allison = "Allison"

    case hinman = "Hinman"

    case plexEast = "Plex East"

    case plexWest = "Plex West"

    case sargent = "Sargent"

}

public let diningHalls: [DiningHall] = [.allison, .hinman, .plexEast, .plexWest, .sargent]

/// An enum representing each cafe or C-Store.
public enum CafeOrCStore: String {

    case plex = "Plex C-Store"

    case frans = "Fran's Café at Willard"

    case kresge = "Kresge Café"

    case bergson = "Café Bergson at Main"

    case techExpress = "Tech Express"

    case coralie = "Café Coralie at Pancoe"

    case lisas = "Lisa's Café at Slivka"

    case hinman = "Hinman C-Store"

    case starbucksTruck = "Starbucks Truck at Mudd"

}

public let cafesAndCStores: [CafeOrCStore] = [.plex, .frans, .kresge, .bergson, .techExpress, .coralie, .lisas, .hinman, .starbucksTruck]

/// An enum representing each location at Norris.
public enum NorrisLocation: String {

    case deli = "Wildcat Deli"

    case pattySquared = "Patty Squared"

    case budlong = "Budlong Hot Chicken"

    case asiana = "Asiana Foodville"

    case cStore = "Market C-Store"

    case starbucks = "Norbucks"

    case modPizza = "MOD Pizza"

    case dunkinDonuts = "Dunkin' Donuts"

}

public let norrisLocations: [NorrisLocation] = [.deli, .pattySquared, .budlong, .asiana, .cStore, .starbucks, .modPizza, .dunkinDonuts]

/// An enum representing the status of dining locations.
public enum DiningStatus: String {

    case open = "Open"

    case closingSoon = "Closing Soon"

    case closed = "Closed"

}

/// In minutes
let closingSoonThreshold = 60

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
        return mwLocalizedString("Sunday", comment: "")
    case 2:
        return mwLocalizedString("Monday", comment: "")
    case 3:
        return mwLocalizedString("Tuesday", comment: "")
    case 4:
        return mwLocalizedString("Wednesday", comment: "")
    case 5:
        return mwLocalizedString("Thursday", comment: "")
    case 6:
        return mwLocalizedString("Friday", comment: "")
    case 7:
        return mwLocalizedString("Saturday", comment: "")
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
        let twentyFourHourTime = twentyFourHourTime % 2400
        var durationString = twentyFourHourTime != 0 ? String(twentyFourHourTime) : "000"
        durationString.insert(":", at: durationString.index(durationString.endIndex, offsetBy: -2))

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "H:mm"
        let refDate = dateFormatter.date(from: durationString)!
        dateFormatter.timeStyle = .short
        if currentLanguage != .default {
            dateFormatter.locale = Locale(identifier: currentLanguage.rawValue)
        }
        return dateFormatter.string(from: refDate)
    }

    public var formattedTimeRange: String? {
        if startingTime == 0 && endingTime == 2400 { return mwLocalizedString("AllDay", comment: "") }
        return String(format: mwLocalizedString("TimeRange: %@ - %@", comment: ""), formattedTime(twentyFourHourTime: startingTime), formattedTime(twentyFourHourTime: endingTime))
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
                return mwLocalizedString("EveryDay", comment: "")
            }
            return String(format: mwLocalizedString("DateRange: %@ - %@", comment: ""), dayOfWeekString(startingDayOfWeek)!, dayOfWeekString(endingDayOfWeek)!)
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
            for i in 0..<scheduleToday.count {
                let scheduleRow = scheduleToday[i]
                let nextScheduleRow = i <= scheduleToday.count - 2 ? scheduleToday[i + 1] : nil
                if date.twentyFourHourTime >= scheduleRow.startingTime && date.twentyFourHourTime < scheduleRow.endingTime {
                    let hourDifferenceFromEndingTime = scheduleRow.endingTime / 100 - date.twentyFourHourTime / 100
                    let minuteDifferenceFromEndingTime = scheduleRow.endingTime % 100 - date.twentyFourHourTime % 100
                    if (hourDifferenceFromEndingTime == 0 && minuteDifferenceFromEndingTime <= closingSoonThreshold || hourDifferenceFromEndingTime == 1 && minuteDifferenceFromEndingTime <= -closingSoonThreshold) && nextScheduleRow?.status == .closed {
                        return .closingSoon
                    }
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
    return diningScheduleDictionaryFromPlist(plistName).keys.compactMap { locationName -> (key: DiningLocation, status: DiningStatus)? in
        let diningStatus = MeowlWatchData.diningStatus(for: DiningLocation(rawValue: locationName)!, at: date)
        return (key: DiningLocation(rawValue: locationName)!, status: diningStatus)
    }
    .sorted { (pair1, pair2) -> Bool in // Sorted by open > closed first, and then by alphabet
        if pair1.status != pair2.status {
            if pair1.status != .closed && pair1.status != .closingSoon { return true }
            else if pair1.status == .closingSoon && pair2.status == .closed { return true }
            else { return false }
        }
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

public var scheduleDisclaimerString: String {
    return mwLocalizedString("ScheduleDisclaimer", comment: "Schedules displayed are for normal school days only")
}
