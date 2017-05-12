//
//  SearchResultsTableViewController.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-05-11.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import UIKit
import MeowlWatchData

class SearchResultsTableViewController: UITableViewController {

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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previewingContext == nil {
            registerForPreviewing()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: animated)
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

    func diningLocation<DiningLocation>(_ diningLocation: DiningLocation, contains string: String) -> Bool where DiningLocation : RawRepresentable, DiningLocation.RawValue == String {
        let normalize: ((String) -> String) = { originalString -> String in
            let allowedCharacterSet = NSMutableCharacterSet()
            allowedCharacterSet.formUnion(with: .alphanumerics)
            allowedCharacterSet.formUnion(with: .whitespaces)
            let utf16Array = originalString.lowercased().utf16.filter { allowedCharacterSet.characterIsMember($0) }
            return String(utf16CodeUnits: utf16Array, count: utf16Array.count).folding(options: .diacriticInsensitive, locale: nil)
        }
        let normalizedQueryString = normalize(string)
        var searchSources: [String] = []
        if let cafeOrCStore = diningLocation as? CafeOrCStore {
            let normalizedLocation = normalize(cafeOrCStore.rawValue)
            searchSources += normalizedLocation.components(separatedBy: " ")
            switch cafeOrCStore {
            case .plex:
                searchSources += ["foster", "walker"]

            case .einstein:
                searchSources += ["brothers", "bros", "bagel"]
            
            case .bergson:
                searchSources += ["university", "library"]
            
            case .techExpress:
                searchSources += ["technological", "institute"]

            default:
                break
            }
        }
        if let diningHall = diningLocation as? DiningHall {
            searchSources += normalize(diningHall.rawValue).components(separatedBy: " ")
            searchSources += ["dining", "hall"]
            if diningHall == .plexEast || diningHall == .plexWest {
                searchSources += ["foster", "walker"]
            }
        }
        if let norrisLocation = diningLocation as? NorrisLocation {
            searchSources += normalize(norrisLocation.rawValue).components(separatedBy: " ")
            searchSources += ["norris"]
            if norrisLocation == .starbucks {
                searchSources += ["starbucks"]
            }
        }

        return searchSources.reduce(false, { result, searchSource -> Bool in
            if searchSource == "at" { return result || false }
            return result || normalizedQueryString.components(separatedBy: " ").reduce(false, { result, normalizedComponent -> Bool in
                if normalizedComponent.isEmpty { return result || false }
                return result || searchSource.hasPrefix(normalizedComponent)
            })
        })
    }

    func registerForPreviewing() {
        if #available(iOS 9.0, *) {
            if traitCollection.forceTouchCapability == .available {
                previewingContext = registerForPreviewing(with: self, sourceView: tableView)
            }
        }
    }

}

extension SearchResultsTableViewController : UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        guard let searchString = searchController.searchBar.text else { return }
        let date = Date()
        filteredCafesAndCStoresStatuses = MeowlWatchData.diningStatuses(at: date).filter { pair -> Bool in
            return diningLocation(pair.key, contains: searchString)
        }
        filteredDiningHallsStatuses = MeowlWatchData.diningStatuses(at: date).filter { pair -> Bool in
            return diningLocation(pair.key, contains: searchString)
        }
        filteredNorrisLocationsStatuses = MeowlWatchData.diningStatuses(at: date).filter { pair -> Bool in
            return diningLocation(pair.key, contains: searchString)
        }
        tableView.reloadData()
    }
    
}

@available(iOS 9.0, *)
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
            return UINavigationController(rootViewController: diningLocationSchedulesTableViewController)
        }
        return nil
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        guard let meowlWatchTableViewController = meowlWatchTableViewController else { return }
        if let viewController = (viewControllerToCommit as? UINavigationController)?.topViewController {
            meowlWatchTableViewController.navigationController!.pushViewController(viewController, animated: false)
        }
    }
    
}
