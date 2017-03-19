//
//  TableViewController.swift
//  NU Points
//
//  Created by Jonathan Chan on 2017-03-18.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {

    var queryResult: QueryResult?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Account", style: .plain, target: self, action: #selector(didTapAccountButton(sender:)))

        self.queryResult = Datastore.lastQuery

        self.refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)

        refreshControl!.beginRefreshing()
        refresh(sender: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return 4
        case 2:
            return 1
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Plan"
        case 1:
            return "Balance"
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell

        // Configure the cell...
        switch indexPath.section {
        case 0:
            cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell")!
            switch indexPath.row {
            case 0:
                cell.textLabel!.text = queryResult?.name ?? "--"
            case 1:
                cell.textLabel!.text = queryResult?.currentPlanName ?? "--"
            default:
                break
            }
        case 1:
            cell = tableView.dequeueReusableCell(withIdentifier: "LeftDetailCell")!
            switch indexPath.row {
            case 0:
                if let queryResult = queryResult, queryResult.isUnlimited {
                    cell.textLabel!.text = "∞"
                } else {
                    cell.textLabel!.text = queryResult?.boardMeals ?? "0"
                }
                cell.detailTextLabel!.text = "Meal Swipes Left 😉"
            case 1:
                cell.textLabel!.text = queryResult?.equivalencyMeals ?? "0"
                cell.detailTextLabel!.text = "Equivalencies Left 😋"
            case 2:
                cell.textLabel!.text = queryResult?.points ?? "0"
                cell.detailTextLabel!.text = "Points Left 😏"
            case 3:
                cell.textLabel!.text = queryResult?.totalCatCash ?? "0.00"
                cell.detailTextLabel!.text = "Cat Cash Left 🤑"
            default:
                break
            }
        case 2:
            cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell")!
            cell.textLabel!.text = "Updated: \(queryResult?.dateUpdatedString ?? "N/A")"
        default:
            cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell")!
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 2 {
            if let error = queryResult?.error {
                switch error {
                case .connectionError:
                    return "Unable to connect to the server. Please make sure your device is connected to the internet."
                case .authenticationError:
                    return "Unable to login to server. Please tap \"Account\" to make sure your NetID and password are correct."
                case .parseError:
                    return "An unknown error has occurred. Please contact the developer of this app."
                }
            } else {
                return "Data Retrieved: \(queryResult?.dateRetrievedString ?? "Never")"
            }
        } else { return nil }
    }

    func refresh(sender: Any?) {
        if Datastore.canQuery {
            Datastore.query() {queryResult in
                self.queryResult = queryResult
                self.tableView!.reloadData()
                self.refreshControl!.endRefreshing()
            }
        }
    }

    func didTapAccountButton(sender: Any?) {

    }

}
