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
                    title = String(format: NSLocalizedString("%@ (Closed)", comment: ""), title!)
                } else if status == .closingSoon {
                    title = String(format: NSLocalizedString("%@ (Closing Soon)", comment: ""), title!)
                }
            }

            let numberOfSections = self.numberOfSections(in: tableView)
            for i in 0..<numberOfSections {
                if i != selectedSectionIndex {
                    hiddenSections.append(i)
                }
            }
        } else if let cafeOrCStore = cafeOrCStore {
            let (selectedRowIndex, selectedSectionIndex) = indexPathOfOpenDiningScheduleEntries(for: cafeOrCStore, at: date)
            if let selectedRowIndex = selectedRowIndex {
                selectedIndexPath = IndexPath(row: selectedRowIndex, section: selectedSectionIndex)
            }

            if title != nil {
                let status = diningStatus(for: cafeOrCStore, at: date)
                if status == .closed {
                    title = String(format: NSLocalizedString("%@ (Closed)", comment: ""), title!)
                } else if status == .closingSoon {
                    title = String(format: NSLocalizedString("%@ (Closing Soon)", comment: ""), title!)
                }
            }

            let numberOfSections = self.numberOfSections(in: tableView)
            for i in 0..<numberOfSections {
                if i != selectedSectionIndex {
                    hiddenSections.append(i)
                }
            }
        } else if let norrisLocation = norrisLocation {
            let (selectedRowIndex, selectedSectionIndex) = indexPathOfOpenDiningScheduleEntries(for: norrisLocation, at: date)
            if let selectedRowIndex = selectedRowIndex {
                selectedIndexPath = IndexPath(row: selectedRowIndex, section: selectedSectionIndex)
            }

            if title != nil {
                let status = diningStatus(for: norrisLocation, at: date)
                if status == .closed {
                    title = String(format: NSLocalizedString("%@ (Closed)", comment: ""), title!)
                } else if status == .closingSoon {
                    title = String(format: NSLocalizedString("%@ (Closing Soon)", comment: ""), title!)
                }
            }

            let numberOfSections = self.numberOfSections(in: tableView)
            for i in 0..<numberOfSections {
                if i != selectedSectionIndex {
                    hiddenSections.append(i)
                }
            }
        }

        clearsSelectionOnViewWillAppear = false

        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
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
        return entries.count
    }

    override func tableView(_ tableView: UITableView, defaultNumberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        guard let entries = entries else { return 0 }
        return entries[section].schedule.count
    }

    override func tableView(_ tableView: UITableView, titleForExpandableHeaderInSection section: Int) -> String? {
        guard let entries = entries else { return nil }
        return entries[section].formattedWeekdayRange
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduleCell", for: indexPath)
        guard let entries = entries else { return super.tableView(tableView, cellForRowAt: indexPath) }

        // Configure the cell...
        let entry = entries[indexPath.section]
        cell.textLabel!.text = entry.formattedTimeRange(atIndex: indexPath.row)
        cell.detailTextLabel!.text = NSLocalizedString(entry.schedule[indexPath.row].status.rawValue, comment: "")
        cell.detailTextLabel!.textColor = entry.schedule[indexPath.row].status != .closed ? view.tintColor : UIColor.red

        cell.isUserInteractionEnabled = indexPath == selectedIndexPath

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == numberOfSections(in: tableView) - 1 {
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
