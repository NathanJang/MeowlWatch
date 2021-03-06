//
//  MeowlWatchTableViewController.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-03-18.
//  Copyright © 2018 Jonathan Chan. All rights reserved.
//

import UIKit
import MeowlWatchData
import SafariServices

/// The main table view controller for MeowlWatch, displaying the user's meal plan.
class MeowlWatchTableViewController: ExpandableTableViewController {

    /// The query result that the table view will work with.
    var queryResult: QueryResult? { return MeowlWatchData.lastQuery }

    var cafesAndCStoresStatuses: [(key: CafeOrCStore, status: DiningStatus)] = []
    var diningHallsStatuses: [(key: DiningHall, status: DiningStatus)] = []
    var norrisLocationsStatuses: [(key: NorrisLocation, status: DiningStatus)] = []

    var searchController: UISearchController?

    var searchResultsTableViewController = SearchResultsTableViewController(style: .plain)

    var previewingContext: UIViewControllerPreviewing?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: mwLocalizedString("MWTVCAccountButtonTitle", comment: "Account"), style: .plain, target: self, action: #selector(didTapAccountButton))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: mwLocalizedString("MWTVCSettingsButtonTitle", comment: "Settings"), style: .plain, target: self, action: #selector(didTapSettingsButton))

        self.refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(didTriggerRefreshControl), for: .valueChanged)

        tableView.register(UINib(nibName: "MeowlWatchUserTableViewCell", bundle: nil), forCellReuseIdentifier: "MeowlWatchUserTableViewCell")
        tableView.register(UINib(nibName: "MeowlWatchTableViewCell", bundle: nil), forCellReuseIdentifier: "MeowlWatchTableViewCell")
        tableView.register(UINib(nibName: "MeowlWatchDiningLocationTableViewCell", bundle: nil), forCellReuseIdentifier: "MeowlWatchDiningLocationTableViewCell")

        hiddenSections = MeowlWatchData.hiddenSections

        definesPresentationContext = true

        let searchController = UISearchController(searchResultsController: searchResultsTableViewController)
        self.searchController = searchController
        navigationItem.searchController = searchController
        searchController.searchBar.placeholder = mwLocalizedString("MWTVCSearchBarPlaceholder", comment: "Search Dining Locations")
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no
        searchController.searchBar.delegate = self
        searchController.searchBar.tintColor = view.tintColor
        searchController.searchResultsUpdater = searchResultsTableViewController

        searchResultsTableViewController.meowlWatchTableViewController = self

        registerForPreviewing()

        updateDiningStatuses()

        tableView.layoutMargins.left = 8

        navigationItem.backBarButtonItem = UIBarButtonItem(title: mwLocalizedString("Back"), style: .plain, target: nil, action: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Here because of strange bug involving table view top margin and such
//        refreshControl!.attributedTitle = NSAttributedString(string: String(format: mwLocalizedString("MWTVCUpdated: %@", comment: "Updated:"), self.queryResult?.dateRetrievedString ?? mwLocalizedString("MWTVCNever", comment: "Never")))
        endRefreshing(animated: false)

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

    @objc func didTriggerRefreshControl() {
        updateDiningStatuses()
        tableView.reloadData()
        refresh(animated: true)
    }

    /// Begins refreshing if needed.
    @objc func refreshIfNeeded(animated: Bool) {
        if MeowlWatchData.shouldRefresh {
            beginRefreshing(animated: animated)
        }
        updateDiningStatuses()
        self.tableView.reloadData()
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
            return 2
        case 2:
            return 2
        case 3:
            return cafesAndCStores.count
        case 4:
            return diningHalls.count
        case 5:
            return norrisLocations.count
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForExpandableHeaderInSection section: Int) -> String? {
        switch section {
        case 1:
            return mwLocalizedString("MWTVCMealsHeading", comment: "Meals")
        case 2:
            return mwLocalizedString("MWTVCDiningDollarsHeading", comment: "Dining Dollars")
        case 3:
            return mwLocalizedString("MWTVCCafesHeading", comment: "Cafés and C-Stores")
        case 4:
            return mwLocalizedString("MWTVCDiningHallsHeading", comment: "Dining Halls")
        case 5:
            return mwLocalizedString("MWTVCNorrisHeading", comment: "Norris")
        default:
            return nil
        }
    }

    /// - Parameter selectable: Whether to show a disclosure indicator and set the correct selection style.
    /// - Returns: A MeowlWatchTableViewCell given the strings.
    func meowlWatchTableViewCell(fromTableView tableView: UITableView, numberString: String, descriptionString: String, selectable: Bool = false) -> MeowlWatchTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MeowlWatchTableViewCell") as! MeowlWatchTableViewCell
        cell.numberLabel.text = numberString
        cell.descriptionLabel.text = descriptionString
        cell.accessoryType = selectable ? .disclosureIndicator : .none
        cell.selectionStyle = selectable ? .default : .none
        return cell
    }

    func diningLocationTableViewCell(fromTableView tableView: UITableView, locationName: String, status: DiningStatus) -> MeowlWatchDiningLocationTableViewCell {
        let diningLocationCell = tableView.dequeueReusableCell(withIdentifier: "MeowlWatchDiningLocationTableViewCell") as! MeowlWatchDiningLocationTableViewCell
        diningLocationCell.locationNameLabel.text = locationName
        diningLocationCell.statusLabel.text = mwLocalizedString(status.rawValue, comment: "Open or Closed")
        switch status {
        case .closed:
            diningLocationCell.statusLabel.textColor = .red
        case .closingSoon:
            diningLocationCell.statusLabel.textColor = .warning
        default:
            diningLocationCell.statusLabel.textColor = .purplePride
        }
        return diningLocationCell
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?

        // Configure the cell...
        // Most of the time we're using `??` to provide a default display behavior when the query result hasn't been formed yet.
        switch indexPath.section {
        case 0: // User cell
            let userCell = tableView.dequeueReusableCell(withIdentifier: "MeowlWatchUserTableViewCell") as! MeowlWatchUserTableViewCell
            userCell.nameLabel.text = queryResult?.name ?? mwLocalizedString(MeowlWatchData.defaultNameString, comment: "Your Name")
            userCell.planLabel.text = queryResult?.currentPlanName ?? mwLocalizedString(MeowlWatchData.defaultSubtitleString, comment: "Tap Here To Get Started")
            cell = userCell
        case 1:
            switch indexPath.row {
            case 0:
                cell = meowlWatchTableViewCell(fromTableView: tableView,
                                               numberString: queryResult?.boardMeals ?? "0",
                                               descriptionString: String.localizedStringWithFormat(mwLocalizedString("MWTVCMealSwipesLeft: %d", comment: "Meal Swipes Left"), queryResult?.numberOfBoardMeals ?? 0))
            case 1:
                cell = meowlWatchTableViewCell(fromTableView: tableView,
                                               numberString: queryResult?.mealExchanges ?? "0",
                                               descriptionString: String.localizedStringWithFormat(mwLocalizedString("MWTVCMealExchangesLeft: %d", comment: "Meal Exchanges Left"), queryResult?.numberOfMealExchanges ?? 0))
            default:
                break
            }
        case 2:
            switch indexPath.row {
            case 0:
                cell = meowlWatchTableViewCell(fromTableView: tableView,
                                               numberString: queryResult?.points ?? "$0.00",
                                               descriptionString: String(format: mwLocalizedString("MWTVCDiningDollarsLeft", comment: "Dining Dollars Left"), queryResult?.points ?? 0))
            case 1:
                cell = meowlWatchTableViewCell(fromTableView: tableView,
                                               numberString: queryResult?.catCash ?? "$0.00",
                                               descriptionString: String(format: mwLocalizedString("MWTVCCatCashLeft", comment: "Cat Cash Left"), queryResult?.catCash ?? 0),
                                               selectable: true)

            default:
                break
            }
        case 3:
            let statuses = cafesAndCStoresStatuses
            let pair = statuses[indexPath.row]
            cell = diningLocationTableViewCell(fromTableView: tableView, locationName: pair.key.rawValue, status: pair.status)
        case 4:
            let statuses = diningHallsStatuses
            let pair = statuses[indexPath.row]
            cell = diningLocationTableViewCell(fromTableView: tableView, locationName: pair.key.rawValue, status: pair.status)
        case 5:
            let statuses = norrisLocationsStatuses
            let pair = statuses[indexPath.row]
            cell = diningLocationTableViewCell(fromTableView: tableView, locationName: pair.key.rawValue, status: pair.status)
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
        case 2:
            return mwLocalizedString("MWTVCAddCatCashMessage", comment: "")

        case 5:
            if let errorString = queryResult?.errorString {
                return "\(errorString)\n\n\(MeowlWatchData.scheduleDisclaimerString)"
            } else {
                return MeowlWatchData.scheduleDisclaimerString
            }
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 0 || indexPath == IndexPath(row: 1, section: 2) || indexPath.section >= 3 { return indexPath }
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

    func schedulesTableViewController(forRowAt indexPath: IndexPath) -> UITableViewController? {
        guard let indexPath = tableView(tableView, willSelectRowAt: indexPath) else { return nil }
        if indexPath.section == 3 {
            let statuses = cafesAndCStoresStatuses
            let location = statuses[indexPath.row].key
            return diningLocationSchedulesTableViewController(for: location)
        } else if indexPath.section == 4 {
            let statuses = diningHallsStatuses
            let location = statuses[indexPath.row].key
            return diningLocationSchedulesTableViewController(for: location)
        } else if indexPath.section == 5 {
            let statuses = norrisLocationsStatuses
            let location = statuses[indexPath.row].key
            return diningLocationSchedulesTableViewController(for: location)
        }

        return nil
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            showSignInAlert()
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        if indexPath == IndexPath(row: 1, section: 2) {
            showCatCashVC()
            return
        }
        if let viewController = schedulesTableViewController(forRowAt: indexPath) {
            self.navigationController!.pushViewController(viewController, animated: true)
        }
    }

    /// Updates the UI to show the spinner and then refresh.
    func beginRefreshing(animated: Bool) {
        guard let refreshControl = refreshControl else { return }
        if !refreshControl.isRefreshing {
            refreshControl.beginRefreshing()
        }
        DispatchQueue.main.async { [unowned self] in
            self.refresh(animated: animated)
        }
    }

    /// Updates the UI to hide the spinner.
    func endRefreshing(animated: Bool) {
        guard let refreshControl = refreshControl else { return }
        refreshControl.attributedTitle = NSAttributedString(string: String(format: mwLocalizedString("MWTVCUpdated: %@", comment: "Updated:"), self.queryResult?.dateRetrievedString ?? mwLocalizedString("MWTVCNever", comment: "Never")))
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
    }

    /// Calls `MeowlWatchData.query` and then provides the appropriate UI feedback.
    func refresh(animated: Bool) {
        if MeowlWatchData.canQuery {
            MeowlWatchData.query { [unowned self] queryResult in
                DispatchQueue.main.async { [unowned self] in
                    if queryResult.error != nil {
                        self.showMessageAlert(title: mwLocalizedString("MWTVCRefreshErrorTitle", comment: "Oops!"), message: queryResult.errorString)
                    }

                    self.tableView.reloadData()

                    self.endRefreshing(animated: animated)
                }
            }
        } else {
            showSignInAlert()
        }
    }

    /// The callback for when the account button is pressed.
    @objc func didTapAccountButton() {
        showSignInAlert()
    }

    /// Shows an alert controller prompting for a NetID and password, and then refreshes when the user is finished.
    func showSignInAlert() {
        let alertController = UIAlertController(title: mwLocalizedString("SignInTitle", comment: "Sign In to Northwestern"), message: mwLocalizedString("SignInMessage", comment: "Why we need their details"), preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "NetID"
            textField.text = MeowlWatchData.netID
        }
        alertController.addTextField { textField in
            textField.placeholder = mwLocalizedString("SignInPasswordPlaceholder", comment: "Password")
            textField.isSecureTextEntry = true
            textField.text = MeowlWatchData.password
        }

        let signInAction = UIAlertAction(title: mwLocalizedString("SignInActionTitle", comment: "Sign In"), style: .default) { [unowned self] _ in
            guard let textFields = alertController.textFields else { return }
            let netID = textFields[0].text ?? ""
            let password = textFields[1].text ?? ""
            _ = MeowlWatchData.updateCredentials(netID: netID, password: password)
            if MeowlWatchData.canQuery {
                self.beginRefreshing(animated: true)
            } else {
                // in case already refreshing
                self.endRefreshing(animated: true)
            }
        }
        let cancelAction = UIAlertAction(title: mwLocalizedString("SignInDismiss", comment: "Cancel"), style: .cancel) { [unowned self] _ in
            self.endRefreshing(animated: true)
        }

        alertController.addAction(signInAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true)
        // Change tint color after presenting to make it the right color
        alertController.view.tintColor = self.view.tintColor
    }

    /// Called when the settings button is tapped.
    @objc func didTapSettingsButton() {
        performSegue(withIdentifier: "ShowSettings", sender: self)
    }

    @objc override func sectionHeaderView(_ sectionHeaderView: MeowlWatchSectionHeaderView, sectionOpened section: Int) {
        super.sectionHeaderView(sectionHeaderView, sectionOpened: section)
        if let index = MeowlWatchData.hiddenSections.firstIndex(of: section) {
            MeowlWatchData.hiddenSections.remove(at: index)
        }
    }

    @objc override func sectionHeaderView(_ sectionHeaderView: MeowlWatchSectionHeaderView, sectionClosed section: Int) {
        super.sectionHeaderView(sectionHeaderView, sectionClosed: section)
        MeowlWatchData.hiddenSections.append(section)
    }

    func registerForPreviewing() {
        if traitCollection.forceTouchCapability == .available {
            previewingContext = registerForPreviewing(with: self, sourceView: tableView)
        }
    }

    func updateDiningStatuses() {
        let date = Date()
        cafesAndCStoresStatuses = MeowlWatchData.diningStatuses(at: date)
        diningHallsStatuses = MeowlWatchData.diningStatuses(at: date)
        norrisLocationsStatuses = MeowlWatchData.diningStatuses(at: date)
    }

    private let addCatCashUrlString = "https://www.dineoncampus.com/northwestern/meal-plan-purchase"

    func showCatCashVC() {
        let url = URL(string: addCatCashUrlString)!
        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredControlTintColor = self.view.tintColor
        self.present(safariVC, animated: true, completion: nil)
    }

}

extension MeowlWatchTableViewController : UIViewControllerPreviewingDelegate {

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location) else { return nil }
        previewingContext.sourceRect = tableView.rectForRow(at: indexPath)
        if let schedulesVC = schedulesTableViewController(forRowAt: indexPath) {
            let navigationController = UINavigationController(rootViewController: schedulesVC)
            return navigationController
        }
        return nil
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        let indexPath = tableView.indexPathForRow(at: previewingContext.sourceRect.origin)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        if let viewController = (viewControllerToCommit as? UINavigationController)?.topViewController {
            self.navigationController?.pushViewController(viewController, animated: false)
        }
    }

}

extension MeowlWatchTableViewController : UISearchBarDelegate {

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
        searchResultsTableViewController.updateDiningStatuses()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
    }

}
