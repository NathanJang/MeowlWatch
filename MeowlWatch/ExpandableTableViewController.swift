//
//  ExpandableTableViewController.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-05-02.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import UIKit

class ExpandableTableViewController: UITableViewController {

    dynamic var hiddenSections: [Int] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        tableView.register(UINib(nibName: "MeowlWatchSectionHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "HeaderView")

        if self.tableView(tableView, titleForExpandableHeaderInSection: 0) != nil {
            tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if hiddenSections.contains(section) {
            return 0
        }

        return self.tableView(tableView, defaultNumberOfRowsInSection: section)
    }

    func tableView(_ tableView: UITableView, defaultNumberOfRowsInSection section: Int) -> Int {
        return 0
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = self.tableView(tableView, titleForExpandableHeaderInSection: section) else { return nil }
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "HeaderView") as! MeowlWatchSectionHeaderView
        headerView.section = section
        headerView.delegate = self
        headerView.titleLabel.text = title.uppercased()
        if hiddenSections.contains(section) {
            headerView.sectionHidden = true
        } else {
            headerView.sectionHidden = false
        }
        headerView.updateDisclosureIndicatorOrientation(animated: false)
        return headerView
    }

    func tableView(_ tableView: UITableView, titleForExpandableHeaderInSection section: Int) -> String? {
        return nil
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 38
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

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

}

extension ExpandableTableViewController: SectionHeaderViewDelegate {

    func sectionHeaderView(_ sectionHeaderView: MeowlWatchSectionHeaderView, sectionOpened section: Int) {
        var indexPathsToInsert: [IndexPath] = []
        let numberOfRowsToInsert = tableView(tableView, defaultNumberOfRowsInSection: section)
        for i in 0..<numberOfRowsToInsert {
            indexPathsToInsert.append(IndexPath(row: i, section: section))
        }
        tableView.beginUpdates()
        tableView.insertRows(at: indexPathsToInsert, with: .middle)
        hiddenSections.remove(at: hiddenSections.index(of: section)!)
        tableView.endUpdates()
    }

    func sectionHeaderView(_ sectionHeaderView: MeowlWatchSectionHeaderView, sectionClosed section: Int) {
        var indexPathsToDelete: [IndexPath] = []
        let numberOfRowsToDelete = tableView(tableView, defaultNumberOfRowsInSection: section)
        for i in 0..<numberOfRowsToDelete {
            indexPathsToDelete.append(IndexPath(row: i, section: section))
        }
        tableView.beginUpdates()
        tableView.deleteRows(at: indexPathsToDelete, with: .middle)
        hiddenSections.append(section)
        tableView.endUpdates()
    }

}
