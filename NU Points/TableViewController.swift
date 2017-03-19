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
        refreshControl!.addTarget(self, action: #selector(beginRefrshing), for: .valueChanged)

        beginRefrshing()
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
            if !Datastore.canQuery {
                return "Please tap \"Account\" to login to Northwestern."
            }
            if queryResult?.error != nil {
                return queryResult?.errorString
            } else {
                return "Data Retrieved: \(queryResult?.dateRetrievedString ?? "Never")"
            }
        } else { return nil }
    }

    func beginRefrshing() {
        self.refreshControl!.beginRefreshing()
        refresh()
    }

    func refresh() {
        if Datastore.canQuery {
            Datastore.query {queryResult in
                self.queryResult = queryResult
                self.tableView!.reloadData()
                self.refreshControl!.endRefreshing()

                if queryResult.error != nil {
                    let alertController = UIAlertController(title: "Oops!", message: queryResult.errorString, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        } else {
            refreshControl!.endRefreshing()
        }
    }

    func didTapAccountButton(sender: Any?) {
        showLoginAlert()
    }

    func showLoginAlert() {
        let alertController = UIAlertController(title: "Login to Northwestern", message: "Your NetID and password will only be sent to \"go.dosa.northwestern.edu\".", preferredStyle: .alert)
        alertController.addTextField {textField in
            textField.placeholder = "NetID"
            textField.text = Datastore.netID
        }
        alertController.addTextField {textField in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }

        let loginAction = UIAlertAction(title: "Login", style: .default) {[weak alertController] alertAction in
            if let alertController = alertController {
                let netID = alertController.textFields![0].text ?? ""
                let password = alertController.textFields![1].text ?? ""
                Datastore.updateCredentials(netID: netID, password: password, persistToKeychain: true)
                self.beginRefrshing()
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(loginAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true)
    }

}
