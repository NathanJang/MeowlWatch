//
//  ExpandableTableViewController.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-05-02.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import UIKit

class ExpandableTableViewController: UITableViewController {

    var hiddenSections: [Int] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        tableView.register(UINib(nibName: "MeowlWatchSectionHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "MeowlWatchSectionHeaderView")

        // If the first section does not have a header, set the correct top insets.
        if self.tableView(tableView, titleForExpandableHeaderInSection: 0) != nil {
            tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

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
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "MeowlWatchSectionHeaderView") as! MeowlWatchSectionHeaderView
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
