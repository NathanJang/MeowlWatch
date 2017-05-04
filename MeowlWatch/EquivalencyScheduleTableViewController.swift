//
//  EquivalencyScheduleTableViewController.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-04-30.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import UIKit
import MeowlWatchData

class EquivalencyScheduleTableViewController: ExpandableTableViewController {

    let equivalencyScheduleEntries = MeowlWatchData.equivalencyScheduleEntries

    var selectedIndexPath = MeowlWatchData.indexPathOfEquivalencyScheduleEntries(at: Date())

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        tableView.register(UINib(nibName: "ScheduleRowTableViewCell", bundle: nil), forCellReuseIdentifier: "EquivalencyScheduleCell")

        let numberOfSections = self.numberOfSections(in: tableView)
        for i in 0..<numberOfSections {
            if i != selectedIndexPath.section {
                hiddenSections.append(i)
            }
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
        return equivalencyScheduleEntries.count
    }

    override func tableView(_ tableView: UITableView, defaultNumberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return equivalencyScheduleEntries[section].schedule.count
    }

    override func tableView(_ tableView: UITableView, titleForExpandableHeaderInSection section: Int) -> String? {
        let entries = MeowlWatchData.equivalencyScheduleEntries[section]
        return entries.formattedWeekdayRange
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EquivalencyScheduleCell", for: indexPath)

        // Configure the cell...
        let entries = equivalencyScheduleEntries[indexPath.section]
        cell.textLabel!.text = entries.formattedTimeRange(atIndex: indexPath.row)
        cell.detailTextLabel!.text = MeowlWatchData.equivalencyExchangeRateString(for: entries.schedule[indexPath.row].status)

        cell.isUserInteractionEnabled = indexPath == selectedIndexPath

        return cell
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

    override func sectionHeaderView(_ sectionHeaderView: MeowlWatchSectionHeaderView, sectionOpened section: Int) {
        super.sectionHeaderView(sectionHeaderView, sectionOpened: section)
        if section == selectedIndexPath.section {
            tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: .none)
        }
    }

}
