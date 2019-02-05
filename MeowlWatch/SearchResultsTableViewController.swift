//
//  SearchResultsTableViewController.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-05-11.
//  Copyright © 2018 Jonathan Chan. All rights reserved.
//

import UIKit
import MeowlWatchData

/// The VC responsible for searching for dining locations.
class SearchResultsTableViewController: UITableViewController {

    var cafesAndCStoresStatuses: [(key: CafeOrCStore, status: DiningStatus)] = []
    var diningHallsStatuses: [(key: DiningHall, status: DiningStatus)] = []
    var norrisLocationsStatuses: [(key: NorrisLocation, status: DiningStatus)] = []

    var filteredCafesAndCStoresStatuses: [(key: CafeOrCStore, status: DiningStatus)] = []
    var filteredDiningHallsStatuses: [(key: DiningHall, status: DiningStatus)] = []
    var filteredNorrisLocationsStatuses: [(key: NorrisLocation, status: DiningStatus)] = []

    weak var meowlWatchTableViewController: MeowlWatchTableViewController?

    var previewingContext: UIViewControllerPreviewing?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        tableView.register(UINib(nibName: "MeowlWatchDiningLocationTableViewCell", bundle: nil), forCellReuseIdentifier: "MeowlWatchDiningLocationTableViewCell")

        tableView.keyboardDismissMode = .interactive
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let indexPathForSelectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPathForSelectedRow, animated: true)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previewingContext == nil {
            registerForPreviewing()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
        case 0:
            return filteredCafesAndCStoresStatuses.count
        case 1:
            return filteredDiningHallsStatuses.count
        case 2:
            return filteredNorrisLocationsStatuses.count
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return filteredCafesAndCStoresStatuses.isEmpty ? nil : "Cafés and C-Stores"
        case 1:
            return filteredDiningHallsStatuses.isEmpty ? nil : "Dining Halls"
        case 2:
            return filteredNorrisLocationsStatuses.isEmpty ? nil : "Norris"
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let meowlWatchTableViewController = meowlWatchTableViewController else { return super.tableView(tableView, cellForRowAt: indexPath) }
        var cell: MeowlWatchDiningLocationTableViewCell?

        // Configure the cell...
        switch indexPath.section {
        case 0:
            let pair = filteredCafesAndCStoresStatuses[indexPath.row]
            cell = meowlWatchTableViewController.diningLocationTableViewCell(fromTableView: tableView, locationName: pair.key.rawValue, status: pair.status)
        case 1:
            let pair = filteredDiningHallsStatuses[indexPath.row]
            cell = meowlWatchTableViewController.diningLocationTableViewCell(fromTableView: tableView, locationName: pair.key.rawValue, status: pair.status)
        case 2:
            let pair = filteredNorrisLocationsStatuses[indexPath.row]
            cell = meowlWatchTableViewController.diningLocationTableViewCell(fromTableView: tableView, locationName: pair.key.rawValue, status: pair.status)
        default:
            break
        }

        return cell!
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let meowlWatchTableViewController = meowlWatchTableViewController else { return }
        var diningLocationSchedulesTableViewController: DiningLocationSchedulesTableViewController?
        switch indexPath.section {
        case 0:
            diningLocationSchedulesTableViewController = meowlWatchTableViewController.diningLocationSchedulesTableViewController(for: filteredCafesAndCStoresStatuses[indexPath.row].key)
        case 1:
            diningLocationSchedulesTableViewController = meowlWatchTableViewController.diningLocationSchedulesTableViewController(for: filteredDiningHallsStatuses[indexPath.row].key)
        case 2:
            diningLocationSchedulesTableViewController = meowlWatchTableViewController.diningLocationSchedulesTableViewController(for: filteredNorrisLocationsStatuses[indexPath.row].key)
        default:
            break
        }
        meowlWatchTableViewController.navigationController!.pushViewController(diningLocationSchedulesTableViewController!, animated: true)
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

    /// Checks whether `diningLocation` and `searchString` match.
    /// - Returns: `true` if there is a match, and `false` otherwise.
    func diningLocation<DiningLocation>(_ diningLocation: DiningLocation, contains searchString: String) -> Bool where DiningLocation : RawRepresentable, DiningLocation.RawValue == String {
        let normalize: ((String) -> String) = { originalString -> String in
            let allowedCharacterSet = NSMutableCharacterSet()
            allowedCharacterSet.formUnion(with: .alphanumerics)
            allowedCharacterSet.formUnion(with: .whitespaces)
            let utf16Array = originalString.lowercased().utf16.filter { allowedCharacterSet.characterIsMember($0) }
            return String(utf16CodeUnits: utf16Array, count: utf16Array.count).folding(options: .diacriticInsensitive, locale: nil)
        }
        let normalizedSearchString = normalize(searchString)
        var searchSources: [String] = []
        if let cafeOrCStore = diningLocation as? CafeOrCStore {
            let normalizedLocation = normalize(cafeOrCStore.rawValue)
            searchSources += normalizedLocation.components(separatedBy: " ")
            switch cafeOrCStore {
            case .plex:
                searchSources += ["foster", "walker"]
            
            case .bergson:
                searchSources += ["university", "library"]
            
            case .techExpress:
                searchSources += ["technological", "institute"]

            default:
                break
            }
            let normalizedStatuses = cafesAndCStoresStatuses.filter { $0.key == cafeOrCStore }.map { normalize($0.status.rawValue) }
            for status in normalizedStatuses {
                searchSources += status.components(separatedBy: " ")
            }
        }
        if let diningHall = diningLocation as? DiningHall {
            searchSources += normalize(diningHall.rawValue).components(separatedBy: " ")
            searchSources += ["dining", "hall"]
            if diningHall == .plexEast || diningHall == .plexWest {
                searchSources += ["foster", "walker"]
            }
            let normalizedStatuses = diningHallsStatuses.filter { $0.key == diningHall }.map { normalize($0.status.rawValue) }
            for status in normalizedStatuses {
                searchSources += status.components(separatedBy: " ")
                if status != "closed" {
                    searchSources += ["open"]
                }
            }
        }
        if let norrisLocation = diningLocation as? NorrisLocation {
            searchSources += normalize(norrisLocation.rawValue).components(separatedBy: " ")
            searchSources += ["norris"]
            switch norrisLocation {
            case .starbucks:
                searchSources += ["starbucks", "coffee"]

            case .modPizza:
                searchSources += ["pizza"]

            case .dunkinDonuts:
                searchSources += ["doughnuts"]

            default:
                break
            }
            let normalizedStatuses = norrisLocationsStatuses.filter { $0.key == norrisLocation }.map { normalize($0.status.rawValue) }
            for status in normalizedStatuses {
                searchSources += status.components(separatedBy: " ")
            }
        }

        return normalizedSearchString.components(separatedBy: " ").reduce(true, { result, normalizedSearchComponent -> Bool in
            if normalizedSearchComponent.isEmpty { return result }
            return result && searchSources.reduce(false, { result, searchSource -> Bool in
                return result || searchSource.hasPrefix(normalizedSearchComponent)
            })
        })
    }

    func registerForPreviewing() {
        if traitCollection.forceTouchCapability == .available {
            previewingContext = registerForPreviewing(with: self, sourceView: tableView)
        }
    }

    /// Fetches dining statuses.
    func updateDiningStatuses() {
        let date = Date()
        cafesAndCStoresStatuses = MeowlWatchData.diningStatuses(at: date)
        diningHallsStatuses = MeowlWatchData.diningStatuses(at: date)
        norrisLocationsStatuses = MeowlWatchData.diningStatuses(at: date)
    }

}

extension SearchResultsTableViewController : UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        guard let searchString = searchController.searchBar.text else { return }
        filteredCafesAndCStoresStatuses = cafesAndCStoresStatuses.filter { pair -> Bool in
            return diningLocation(pair.key, contains: searchString)
        }
        filteredDiningHallsStatuses = diningHallsStatuses.filter { pair -> Bool in
            return diningLocation(pair.key, contains: searchString)
        }
        filteredNorrisLocationsStatuses = norrisLocationsStatuses.filter { pair -> Bool in
            return diningLocation(pair.key, contains: searchString)
        }
        tableView.reloadData()
    }
    
}

extension SearchResultsTableViewController : UIViewControllerPreviewingDelegate {

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let meowlWatchTableViewController = meowlWatchTableViewController else { return nil }
        guard let indexPath = tableView.indexPathForRow(at: location) else { return nil }
        previewingContext.sourceRect = tableView.rectForRow(at: indexPath)
        var diningLocationSchedulesTableViewController: DiningLocationSchedulesTableViewController?
        switch indexPath.section {
        case 0:
            diningLocationSchedulesTableViewController = meowlWatchTableViewController.diningLocationSchedulesTableViewController(for: filteredCafesAndCStoresStatuses[indexPath.row].key)
        case 1:
            diningLocationSchedulesTableViewController = meowlWatchTableViewController.diningLocationSchedulesTableViewController(for: filteredDiningHallsStatuses[indexPath.row].key)
        case 2:
            diningLocationSchedulesTableViewController = meowlWatchTableViewController.diningLocationSchedulesTableViewController(for: filteredNorrisLocationsStatuses[indexPath.row].key)
        default:
            break
        }
        if let diningLocationSchedulesTableViewController = diningLocationSchedulesTableViewController {
            let navigationController = UINavigationController(rootViewController: diningLocationSchedulesTableViewController)
            navigationController.viewWillAppear(false)
            return navigationController
        }
        return nil
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        guard let meowlWatchTableViewController = meowlWatchTableViewController else { return }
        let indexPath = tableView.indexPathForRow(at: previewingContext.sourceRect.origin)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        if let viewController = (viewControllerToCommit as? UINavigationController)?.topViewController {
            meowlWatchTableViewController.navigationController!.pushViewController(viewController, animated: false)
        }
    }
    
}
