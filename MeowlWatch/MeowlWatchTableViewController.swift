//
//  TableViewController.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-03-18.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import UIKit
import GoogleMobileAds

/// The main table view controller for MeowlWatch, displaying the user's meal plan.
class MeowlWatchTableViewController: UITableViewController {

    /// The Google ad banner.
    var bannerView: GADBannerView?

    /// The Google interstitial controller.
    var interstitial: GADInterstitial?

    /// The query result that the table view will work with.
    var queryResult: QueryResult?

    /// Whether `viewDidAppear(_:)` has been called for the first time.
    var hasAppeared = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Account", style: .plain, target: self, action: #selector(didTapAccountButton))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(didTapSettingsButton))

        self.queryResult = Datastore.lastQuery

        self.refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(refresh), for: .valueChanged)

        if Datastore.shouldDisplayAds {
            self.bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
            let bannerView = self.bannerView!
            self.navigationController!.setToolbarHidden(false, animated: false)
            self.navigationController!.toolbar.addSubview(bannerView)
            bannerView.adUnitID = Datastore.adMobBannerAdUnitID
            bannerView.rootViewController = self
            let bannerRequest = GADRequest()
            bannerView.load(bannerRequest)

            if arc4random_uniform(4) < 1 {
                self.interstitial = GADInterstitial(adUnitID: Datastore.adMobInterstitialAdUnitID)
                interstitial!.delegate = self
                let interstitialRequest = GADRequest()
                interstitial!.load(interstitialRequest)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !hasAppeared {
            if Datastore.shouldRefresh {
                beginRefrshing()
            }

            hasAppeared = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
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
        // Most of the time we're using `??` to provide a default display behavior when the query result hasn't been formed yet.
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
                cell.textLabel!.text = queryResult?.boardMeals ?? "0"
                cell.detailTextLabel!.text = "\(QueryResult.description(forItem: .boardMeals, withQuery: queryResult)) Left"
            case 1:
                cell.textLabel!.text = queryResult?.equivalencyMeals ?? "0"
                cell.detailTextLabel!.text = "\(QueryResult.description(forItem: .equivalencyMeals, withQuery: queryResult)) Left"
            case 2:
                cell.textLabel!.text = queryResult?.points ?? "0"
                cell.detailTextLabel!.text = "\(QueryResult.pointsDescription) Left"
            case 3:
                cell.textLabel!.text = queryResult?.totalCatCash ?? "0.00"
                cell.detailTextLabel!.text = "\(QueryResult.catCashDescription) Left"
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
        switch section {
        case 2:
            return "Data Retrieved: \(queryResult?.dateRetrievedString ?? "Never")"
        case 3:
            if Datastore.canQuery {
                return queryResult?.errorString ?? "Note: The Northwestern server usually updates your balance every 30 minutes."
            } else {
                return "Please tap \"Account\" and enter your NetID and password."
            }
        default:
            return nil
        }
    }

    /// Updates the UI to show the spinner and then refresh.
    func beginRefrshing() {
        DispatchQueue.main.async {
            self.refreshControl!.beginRefreshing()
            self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentOffset.y - self.refreshControl!.frame.height), animated: true)
        }
        refresh()
    }

    /// Updates the UI to hide the spinner.
    func endRefreshing() {
        DispatchQueue.main.async {
            self.refreshControl!.endRefreshing()
            self.tableView.setContentOffset(CGPoint(x: 0, y: -self.tableView.contentInset.top), animated: true)
        }
    }

    /// Calls `Datastore.query` and then provides the appropriate UI feedback.
    func refresh() {
        if Datastore.canQuery {
            Datastore.query {queryResult in
                self.queryResult = queryResult
                self.tableView.reloadData()
                DispatchQueue.main.async {
                    self.endRefreshing()
                }

                if queryResult.error != nil {
                    let alertController = UIAlertController(title: "Oops!", message: queryResult.errorString, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        } else {
            self.endRefreshing()
            showLoginAlert()
        }
    }

    /// The callback for when the account button is pressed.
    func didTapAccountButton() {
        showLoginAlert()
    }

    /// Shows an alert controller prompting for a NetID and password, and then refreshes when the user is finished.
    func showLoginAlert() {
        let alertController = UIAlertController(title: "Login to Northwestern", message: "Your NetID and password will only be sent securely to \"go.dosa.northwestern.edu\".", preferredStyle: .alert)
        alertController.addTextField {textField in
            textField.placeholder = "NetID"
            textField.text = Datastore.netID
        }
        alertController.addTextField {textField in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
            textField.text = Datastore.password
        }

        let loginAction = UIAlertAction(title: "Login", style: .default) {[weak alertController] alertAction in
            if let alertController = alertController {
                let netID = alertController.textFields![0].text ?? ""
                let password = alertController.textFields![1].text ?? ""
                Datastore.updateCredentials(netID: netID, password: password)
                self.beginRefrshing()
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(loginAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true)
        // Change tint color after presenting to make it the right color
        alertController.view.tintColor = self.view.tintColor
    }

    /// Called when the settings button is tapped.
    func didTapSettingsButton() {
        performSegue(withIdentifier: "ShowSettings", sender: self)
    }

}

extension MeowlWatchTableViewController: GADInterstitialDelegate {

    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        if Datastore.shouldDisplayAds && Datastore.canQuery && ad.isReady {
            ad.present(fromRootViewController: self)

            if ad.adUnitID == Datastore.adMobInterstitialAdUnitID {
                self.interstitial = nil
            }
        }
    }

}