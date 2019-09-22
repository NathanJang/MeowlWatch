//
//  DiningLocationSchedulesTableViewController.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-04-30.
//  Copyright © 2018 Jonathan Chan. All rights reserved.
//

import UIKit
import MeowlWatchData

/// A VC responsible for showing schedules for a single dining location.
class DiningLocationSchedulesTableViewController: ExpandableTableViewController {

    var entries: [ScheduleEntry<DiningStatus>]?

    /// The dining hall, if the location in question is one.
    var diningHall: DiningHall?

    var locationId: String?

    var mapUrl: String?

    /// The cafe, if the location in question is one.
    var cafeOrCStore: CafeOrCStore?

    /// The Norris location, if the location in question is one.
    var norrisLocation: NorrisLocation?

    /// The index path to highlight.
    var selectedIndexPath: IndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        tableView.register(UINib(nibName: "ScheduleRowTableViewCell", bundle: nil), forCellReuseIdentifier: "ScheduleCell")
        let date = Date()

        if let diningHall = diningHall {
            let (selectedRowIndex, selectedSectionIndex) = indexPathOfOpenDiningScheduleEntries(for: diningHall, at: date)
            if let selectedRowIndex = selectedRowIndex {
                selectedIndexPath = IndexPath(row: selectedRowIndex, section: selectedSectionIndex)
            }

            if title != nil {
                let status = diningStatus(for: diningHall, at: date)
                if status == .closed {
                    title = String(format: mwLocalizedString("%@ (Closed)", comment: ""), title!)
                } else if status == .closingSoon {
                    title = String(format: mwLocalizedString("%@ (Closing Soon)", comment: ""), title!)
                }
            }

            let numberOfSections = self.numberOfSections(in: tableView)
            for i in 0..<numberOfSections {
                if i != selectedSectionIndex {
                    hiddenSections.append(i)
                }
            }

            locationId = diningLocationIds[diningHall.rawValue]
            mapUrl = mapUrls[diningHall.rawValue]
        } else if let cafeOrCStore = cafeOrCStore {
            let (selectedRowIndex, selectedSectionIndex) = indexPathOfOpenDiningScheduleEntries(for: cafeOrCStore, at: date)
            if let selectedRowIndex = selectedRowIndex {
                selectedIndexPath = IndexPath(row: selectedRowIndex, section: selectedSectionIndex)
            }

            if title != nil {
                let status = diningStatus(for: cafeOrCStore, at: date)
                if status == .closed {
                    title = String(format: mwLocalizedString("%@ (Closed)", comment: ""), title!)
                } else if status == .closingSoon {
                    title = String(format: mwLocalizedString("%@ (Closing Soon)", comment: ""), title!)
                }
            }

            let numberOfSections = self.numberOfSections(in: tableView)
            for i in 0..<numberOfSections {
                if i != selectedSectionIndex {
                    hiddenSections.append(i)
                }
            }
            mapUrl = mapUrls[cafeOrCStore.rawValue]
        } else if let norrisLocation = norrisLocation {
            let (selectedRowIndex, selectedSectionIndex) = indexPathOfOpenDiningScheduleEntries(for: norrisLocation, at: date)
            if let selectedRowIndex = selectedRowIndex {
                selectedIndexPath = IndexPath(row: selectedRowIndex, section: selectedSectionIndex)
            }

            if title != nil {
                let status = diningStatus(for: norrisLocation, at: date)
                if status == .closed {
                    title = String(format: mwLocalizedString("%@ (Closed)", comment: ""), title!)
                } else if status == .closingSoon {
                    title = String(format: mwLocalizedString("%@ (Closing Soon)", comment: ""), title!)
                }
            }

            let numberOfSections = self.numberOfSections(in: tableView)
            for i in 0..<numberOfSections {
                if i != selectedSectionIndex {
                    hiddenSections.append(i)
                }
            }
            mapUrl = mapUrls[norrisLocation.rawValue]
        }

        tableView.allowsMultipleSelection = true
        clearsSelectionOnViewWillAppear = false

        navigationItem.largeTitleDisplayMode = .never
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .none)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        guard let entries = entries else { return 0 }
        var numberOfSections = entries.count
        if locationId != nil || mapUrl != nil { numberOfSections += 1 }
        return numberOfSections
    }

    override func tableView(_ tableView: UITableView, defaultNumberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == numberOfSections(in: tableView) - 1 && (locationId != nil || mapUrl != nil) {
            var numberOfRows = 0
            if locationId != nil { numberOfRows += 1 }
            if mapUrl != nil { numberOfRows += 1 }
            return numberOfRows
        }
        guard let entries = entries else { return 0 }
        return entries[section].schedule.count
    }

    override func tableView(_ tableView: UITableView, titleForExpandableHeaderInSection section: Int) -> String? {
        if section == numberOfSections(in: tableView) - 1 && (locationId != nil || mapUrl != nil) { return nil }
        guard let entries = entries else { return nil }
        return entries[section].formattedWeekdayRange
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == numberOfSections(in: tableView) - 1 {
            if locationId != nil && indexPath.row == 0 {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = mwLocalizedString("SeeMenu")
                cell.accessoryType = .disclosureIndicator
                return cell
            }
            if mapUrl != nil {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = mwLocalizedString("SeeMap")
                cell.accessoryType = .disclosureIndicator
                return cell
            }
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduleCell", for: indexPath)
        guard let entries = entries else { return super.tableView(tableView, cellForRowAt: indexPath) }

        // Configure the cell...
        let entry = entries[indexPath.section]
        cell.textLabel!.text = entry.formattedTimeRange(atIndex: indexPath.row)
        cell.detailTextLabel!.text = mwLocalizedString(entry.schedule[indexPath.row].status.rawValue, comment: "")
        cell.detailTextLabel!.textColor = entry.schedule[indexPath.row].status != .closed ? view.tintColor : UIColor.red

        cell.isUserInteractionEnabled = indexPath == selectedIndexPath

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == numberOfSections(in: tableView) - 1 {
            if locationId != nil && indexPath.row == 0 {
                tableView.deselectRow(at: indexPath, animated: true)

                let menuVC = MenuTableViewController(style: .grouped)
                menuVC.locationId = locationId!
                menuVC.title = String(format: mwLocalizedString("MenuFor: %@"), title!)
                navigationController?.pushViewController(menuVC, animated: true)
                return
            }
            if mapUrl != nil {
                tableView.deselectRow(at: indexPath, animated: true)

                UIApplication.shared.open(URL(string: mapUrl!)!)
            }
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if indexPath.section != 0 {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let numberOfSections = self.numberOfSections(in: tableView)
        if section == numberOfSections - 1 && (locationId == nil && mapUrl == nil) || section == numberOfSections - 2 && (locationId != nil || mapUrl != nil) {
            return MeowlWatchData.scheduleDisclaimerString
        }
        return nil
    }

    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */

    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */

    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

     }
     */

    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */

    @objc override func sectionHeaderView(_ sectionHeaderView: MeowlWatchSectionHeaderView, sectionOpened section: Int) {
        super.sectionHeaderView(sectionHeaderView, sectionOpened: section)
        if section == selectedIndexPath?.section {
            tableView.selectRow(at: selectedIndexPath!, animated: true, scrollPosition: .none)
        }
    }

}
