//
//  MeowlWatchTableViewController.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-03-18.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import UIKit
import MeowlWatchData

/// The main table view controller for MeowlWatch, displaying the user's meal plan.
class MeowlWatchTableViewController: ExpandableTableViewController {

    /// The query result that the table view will work with.
    var queryResult: QueryResult? { return MeowlWatchData.lastQuery }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Account", style: .plain, target: self, action: #selector(didTapAccountButton))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(didTapSettingsButton))

        self.refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(didTriggerRefreshControl), for: .valueChanged)

        tableView.register(UINib(nibName: "MeowlWatchUserTableViewCell", bundle: nil), forCellReuseIdentifier: "MeowlWatchUserTableViewCell")
        tableView.register(UINib(nibName: "MeowlWatchTableViewCell", bundle: nil), forCellReuseIdentifier: "MeowlWatchTableViewCell")
        tableView.register(UINib(nibName: "MeowlWatchDiningLocationTableViewCell", bundle: nil), forCellReuseIdentifier: "MeowlWatchDiningLocationTableViewCell")

        hiddenSections = [3, 4, 5]

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Here because of strange bug involving table view top margin and such
        refreshControl!.attributedTitle = NSAttributedString(string: "Updated: \(self.queryResult?.dateRetrievedString ?? "Never")")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Deselect the right cell with animation
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: animated)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.refreshIfNeeded(animated: animated)
    }

    func didTriggerRefreshControl() {
        refresh(animated: true)
    }

    /// Begins frefreshing if needed.
    func refreshIfNeeded(animated: Bool) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        if MeowlWatchData.shouldRefresh {
            beginRefrshing(animated: animated)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 6
    }

    override func tableView(_ tableView: UITableView, defaultNumberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 3
        case 2:
            if let queryResult = queryResult, queryResult.catCashInCents == 0 { return 1 }
            else { return 2 }
        case 3:
            let statuses: [(key: CafeOrCStore, status: DiningStatus)] = diningStatuses(at: Date())
            return statuses.count
        case 4:
            let statuses: [(key: DiningHall, status: DiningStatus)] = diningStatuses(at: Date())
            return statuses.count
        case 5:
            let statuses: [(key: NorrisLocation, status: DiningStatus)] = diningStatuses(at: Date())
            return statuses.count
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForExpandableHeaderInSection section: Int) -> String? {
        switch section {
        case 1:
            return "Meals"
        case 2:
            return "Points"
        case 3:
            return "Cafés and C-Stores"
        case 4:
            return "Dining Halls"
        case 5:
            return "Norris"
        default:
            return nil
        }
    }

    /// - Param selectable: Whether to show a disclosure indicator and set the correct selection style.
    /// - Returns: A MeowlWatchTableViewCell given the strings.
    func meowlWatchTableViewCell(fromTableView tableView: UITableView, numberString: String, descriptionString: String, selectable: Bool = false) -> MeowlWatchTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MeowlWatchTableViewCell") as! MeowlWatchTableViewCell
        cell.numberLabel.text = numberString
        cell.descriptionLabel.text = descriptionString
        cell.accessoryType = selectable ? .disclosureIndicator : .none
        cell.selectionStyle = selectable ? .default : .none
        return cell
    }

    func diningLocationTableViewCell(fromTableView tableView: UITableView, locationName: String, stateString: DiningStatus) {}

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?

        // Configure the cell...
        // Most of the time we're using `??` to provide a default display behavior when the query result hasn't been formed yet.
        switch indexPath.section {
        case 0: // User cell
            let userCell = tableView.dequeueReusableCell(withIdentifier: "MeowlWatchUserTableViewCell") as! MeowlWatchUserTableViewCell
            userCell.nameLabel.text = queryResult?.name ?? "Your Name"
            userCell.planLabel.text = queryResult?.currentPlanName ?? "Your Meal Plan"
            cell = userCell
        case 1:
            switch indexPath.row {
            case 0:
                cell = meowlWatchTableViewCell(fromTableView: tableView,
                                               numberString: queryResult?.equivalencyMeals ?? "0",
                                               descriptionString: "\(QueryResult.description(forItem: .equivalencyMeals, withQuery: queryResult)) Left")
            case 1:
                cell = meowlWatchTableViewCell(fromTableView: tableView,
                                               numberString: equivalencyExchangeRateString(at: Date()),
                                               descriptionString: "Per Equivalency Now",
                                               selectable: true)
            case 2:
                cell = meowlWatchTableViewCell(fromTableView: tableView,
                                               numberString: queryResult?.boardMeals ?? "0.00",
                                               descriptionString: "\(QueryResult.description(forItem: .boardMeals, withQuery: queryResult)) Left")
            default:
                break
            }
        case 2:
            switch indexPath.row {
            case 0:
                cell = meowlWatchTableViewCell(fromTableView: tableView,
                                               numberString: queryResult?.points ?? "0",
                                               descriptionString: "\(QueryResult.description(forItem: .points, withQuery: queryResult)) Left")
            case 1:
                cell = meowlWatchTableViewCell(fromTableView: tableView,
                                               numberString: queryResult?.catCash ?? "0",
                                               descriptionString: "\(QueryResult.description(forItem: .catCash, withQuery: queryResult)) Left")
            default:
                break
            }
        case 3:
            let diningLocationCell = tableView.dequeueReusableCell(withIdentifier: "MeowlWatchDiningLocationTableViewCell", for: indexPath) as! MeowlWatchDiningLocationTableViewCell
            let statuses: [(key: CafeOrCStore, status: DiningStatus)] = diningStatuses(at: Date())
            let result = statuses[indexPath.row]
            diningLocationCell.locationNameLabel.text = result.key.rawValue
            diningLocationCell.stateLabel.text = result.status.rawValue
            diningLocationCell.stateLabel.textColor = result.status != .closed ? UIColor(red: 128/255, green: 0, blue: 1, alpha: 1) : UIColor.red
            cell = diningLocationCell
        case 4:
            let diningLocationCell = tableView.dequeueReusableCell(withIdentifier: "MeowlWatchDiningLocationTableViewCell", for: indexPath) as! MeowlWatchDiningLocationTableViewCell
            let statuses: [(key: DiningHall, status: DiningStatus)] = diningStatuses(at: Date())
            let result = statuses[indexPath.row]
            diningLocationCell.locationNameLabel.text = result.key.rawValue
            diningLocationCell.stateLabel.text = result.status.rawValue
            diningLocationCell.stateLabel.textColor = result.status != .closed ? UIColor(red: 128/255, green: 0, blue: 1, alpha: 1) : UIColor.red
            cell = diningLocationCell
        case 5:
            let diningLocationCell = tableView.dequeueReusableCell(withIdentifier: "MeowlWatchDiningLocationTableViewCell", for: indexPath) as! MeowlWatchDiningLocationTableViewCell
            let statuses: [(key: NorrisLocation, status: DiningStatus)] = diningStatuses(at: Date())
            let result = statuses[indexPath.row]
            diningLocationCell.locationNameLabel.text = result.key.rawValue
            diningLocationCell.stateLabel.text = result.status.rawValue
            diningLocationCell.stateLabel.textColor = result.status != .closed ? UIColor(red: 128/255, green: 0, blue: 1, alpha: 1) : UIColor.red
            cell = diningLocationCell
        default:
            break
        }

        return cell!
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 75
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 5:
            if MeowlWatchData.canQuery {
                return queryResult?.errorString ?? "Schedules are based on normal school days Fall through Spring Quarter, and may differ.\n\nWeekly plans reset on Sundays at 7 AM Central Time."
            } else {
                return "Please tap \"Account\" and enter your NetID and password."
            }
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath == IndexPath(row: 1, section: 1 ) || indexPath.section >= 3 { return indexPath }
        else { return nil }
    }

    func diningLocationSchedulesTableViewController<DiningLocation>(for location: DiningLocation) -> DiningLocationSchedulesTableViewController where DiningLocation : RawRepresentable, DiningLocation.RawValue == String {
        let viewController = DiningLocationSchedulesTableViewController(style: .grouped)
        if let cafeOrCStore = location as? CafeOrCStore {
            viewController.cafeOrCStore = cafeOrCStore
        }
        if let diningHall = location as? DiningHall {
            viewController.diningHall = diningHall
        }
        if let norrisLocation = location as? NorrisLocation {
            viewController.norrisLocation = norrisLocation
        }
        viewController.entries = openDiningScheduleEntries(for: location)
        viewController.title = location.rawValue
        viewController.view.tintColor = view.tintColor
        return viewController
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == IndexPath(row: 1, section: 1) {
            self.performSegue(withIdentifier: "ShowEquivalencySchedule", sender: self)
        } else if indexPath.section == 3 {
            let statuses: [(key: CafeOrCStore, status: DiningStatus)] = diningStatuses(at: Date())
            let location = statuses[indexPath.row].key
            let viewController = diningLocationSchedulesTableViewController(for: location)
            DispatchQueue.main.async {
                self.navigationController!.pushViewController(viewController, animated: true)
            }
        } else if indexPath.section == 4 {
            let statuses: [(key: DiningHall, status: DiningStatus)] = diningStatuses(at: Date())
            let location = statuses[indexPath.row].key
            let viewController = diningLocationSchedulesTableViewController(for: location)
            DispatchQueue.main.async {
                self.navigationController!.pushViewController(viewController, animated: true)
            }
        } else {
            let statuses: [(key: NorrisLocation, status: DiningStatus)] = diningStatuses(at: Date())
            let location = statuses[indexPath.row].key
            let viewController = diningLocationSchedulesTableViewController(for: location)
            DispatchQueue.main.async {
                self.navigationController!.pushViewController(viewController, animated: true)
            }
        }
    }

    /// Updates the UI to show the spinner and then refresh.
    func beginRefrshing(animated: Bool) {
        DispatchQueue.main.async {
            self.refreshControl!.beginRefreshing()
            self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentOffset.y - self.refreshControl!.frame.height), animated: animated)
        }
        refresh(animated: animated)
    }

    /// Updates the UI to hide the spinner.
    func endRefreshing(animated: Bool) {
        DispatchQueue.main.async {
            self.refreshControl!.attributedTitle = NSAttributedString(string: "Retrieved: \(self.queryResult?.dateRetrievedString ?? "Never")")
            self.refreshControl!.endRefreshing()
        }
    }

    /// Calls `MeowlWatchData.query` and then provides the appropriate UI feedback.
    func refresh(animated: Bool) {
        if MeowlWatchData.canQuery {
            MeowlWatchData.query { queryResult in
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                self.endRefreshing(animated: animated)

                if queryResult.error != nil {
                    self.showMessageAlert(title: "Oops!", message: queryResult.errorString)
                }
            }
        } else {
            self.endRefreshing(animated: animated)
            showSignInAlert()
        }
    }

    /// The callback for when the account button is pressed.
    func didTapAccountButton() {
        showSignInAlert()
    }

    /// Shows an alert controller prompting for a NetID and password, and then refreshes when the user is finished.
    func showSignInAlert() {
        let alertController = UIAlertController(title: "Sign In to Northwestern", message: "Your NetID and password will only be sent securely to \"websso.it.northwestern.edu\".", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "NetID"
            textField.text = MeowlWatchData.netID
        }
        alertController.addTextField { textField in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
            textField.text = MeowlWatchData.password
        }

        let signInAction = UIAlertAction(title: "Sign In", style: .default) { alertAction in
            let netID = alertController.textFields![0].text ?? ""
            let password = alertController.textFields![1].text ?? ""
            _ = MeowlWatchData.updateCredentials(netID: netID, password: password)
            self.beginRefrshing(animated: true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(signInAction)
        alertController.addAction(cancelAction)

        DispatchQueue.main.async {
            self.present(alertController, animated: true)
            // Change tint color after presenting to make it the right color
            alertController.view.tintColor = self.view.tintColor
        }
    }

    /// Called when the settings button is tapped.
    func didTapSettingsButton() {
        performSegue(withIdentifier: "ShowSettings", sender: self)
    }

}
