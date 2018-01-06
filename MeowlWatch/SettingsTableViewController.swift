//
//  SettingsTableViewController.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-03-23.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import UIKit
import MeowlWatchData

#if !MEOWLWATCH_FULL
    import StoreKit
#endif

/// A view controller for the settings.
class SettingsTableViewController: UITableViewController {

    #if !MEOWLWATCH_FULL
        /// The widget's IAP product, which will exist after we query the app store.
        var widgetProduct: SKProduct?

        /// Whether StoreKit can make payments, set before querying the app store.
        var canMakePayments = false
    #endif

    /// The logo designer's website's URL.
    let isabelURLString = "https://isabel6389.wixsite.com/website"

    /// Shortened URL for designer's website.
    let isabelShortURLString = "http://goo.gl/0IFpAi"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        self.setEditing(true, animated: false)

        #if !MEOWLWATCH_FULL
            if !MeowlWatchData.anythingIsPurchased {
                let refreshControl = UIRefreshControl()
                self.refreshControl = refreshControl
                refreshControl.addTarget(self, action: #selector(requestProductData), for: .valueChanged)
                requestProductData()
            }
            SKPaymentQueue.default().add(self)
        #endif

        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: animated)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        #if !MEOWLWATCH_FULL
            if !MeowlWatchData.anythingIsPurchased && !canMakePayments {
                showCannotMakePaymentsAlert()
            }
        #endif
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        #if !MEOWLWATCH_FULL
            SKPaymentQueue.default().remove(self)
        #endif
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if MeowlWatchData.widgetIsPurchased {
                return MeowlWatchData.widgetArrangement.count
            } else {
                return 3
            }
        case 1:
            return 1
        case 2:
            return 2
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Widget"
        case 1:
            return "Logo"
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        // Configure the cell...
        switch indexPath.section {
        case 0:
            if MeowlWatchData.widgetIsPurchased {
                cell = tableView.dequeueReusableCell(withIdentifier: "WidgetArrangementCell", for: indexPath)

                let item = MeowlWatchData.widgetArrangement[indexPath.row]
                cell!.textLabel!.text = QueryResult.description(forItem: item, withQuery: nil)
            } else {
                #if !MEOWLWATCH_FULL
                    switch indexPath.row {
                    case 0:
                        if isRefreshing {
                            cell = tableView.dequeueReusableCell(withIdentifier: "LoadingButtonCell", for: indexPath)
                            cell!.textLabel!.text = "Loading..."
                        } else {
                            cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath)
                            if let widgetProduct = widgetProduct {
                                cell!.textLabel!.text = widgetProduct.localizedTitle
                            } else {
                                cell!.textLabel!.text = "(In-App Purchase Unavailable)"
                            }
                        }

                    case 1:
                        cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath)
                        cell!.textLabel!.text = "Restore Purchases"

                    case 2:
                        cell = tableView.dequeueReusableCell(withIdentifier: "WidgetPreviewCell", for: indexPath)

                    default:
                        break
                    }
                #endif
            }
        case 1:
            cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath)
            cell!.textLabel!.text = "Visit Designer's Website"

        case 2:
            cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath)
            switch indexPath.row {
            case 0:
                cell!.textLabel!.text = "Send Feedback by Email"
            case 1:
                cell!.textLabel!.text = "Show Legal"
            default:
                break
            }
            
        default:
            break
        }

        return cell!
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if !MeowlWatchData.widgetIsPurchased && indexPath == IndexPath(row: 2, section: 0) {
            return 488
        }

        return UITableViewAutomaticDimension
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if !MeowlWatchData.widgetIsPurchased && indexPath == IndexPath(row: 2, section: 0) {
            let imageSize = #imageLiteral(resourceName: "WidgetPreviewFull").size
            return self.view.frame.width * imageSize.height / imageSize.width
        }

        return UITableViewAutomaticDimension
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            if MeowlWatchData.widgetIsPurchased {
                return "The MeowlWatch widget may be added to the Today View on the Notification Center. Items will appear in this arrangement."
            } else {
                return "Making useful apps like MeowlWatch is hard work. Please consider leaving me a tip above! :) Ads will also be disabled."
            }
        case 1:
            return "The MeowlWatch logo was designed by Isabel Nygard. Visit \(isabelURLString) to see more."
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        switch indexPath.section {
        case 0:
            return MeowlWatchData.widgetIsPurchased
        default:
            return false
        }
    }

    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        switch indexPath.section {
        case 0:
            return MeowlWatchData.widgetIsPurchased
        default:
            return false
        }
    }

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

    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            let row = sourceIndexPath.section < proposedDestinationIndexPath.section ? tableView.numberOfRows(inSection: sourceIndexPath.section) - 1 : 0
            return IndexPath(row: row, section: sourceIndexPath.section)
        }

        return proposedDestinationIndexPath
    }

    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        MeowlWatchData.moveWidgetArrangement(fromIndex: fromIndexPath.row, toIndex: to.row)
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            if !MeowlWatchData.widgetIsPurchased {
                #if !MEOWLWATCH_FULL
                    if let refreshControl = refreshControl, !refreshControl.isRefreshing {
                        switch indexPath.row {
                        case 0:
                            if canMakePayments {
                                if widgetProduct != nil {
                                    buyWidgetIfAvailable()
                                } else {
                                    self.showMessageAlert(title: "In-App Purchase Unavailable", message: "Please check your internet connection. Or, iTunes may be having some trouble with in-app purchases at the moment. Please try again later.")
                                }
                            } else {
                                showCannotMakePaymentsAlert()
                            }

                        case 1:
                            self.beginRefreshing()
                            SKPaymentQueue.default().restoreCompletedTransactions()

                        default:
                            break
                        }
                    }
                #endif
                tableView.deselectRow(at: indexPath, animated: true)
            }

        case 1:
            self.showActionPrompt(title: "Open Isabel Nygard's Website?", message: "Isabel Nygard is a Northwestern undergraduate student studying Art Theory & Practice and Materials Science & Engineering.", action:  {
                if let url = URL(string: self.isabelShortURLString) {
                    UIApplication.shared.openURL(url)
                }
            })
            tableView.deselectRow(at: indexPath, animated: true)

        case 2:
            switch indexPath.row {
            case 0:
                self.showActionPrompt(title: "Open Email App?", message: "Please send feedback to JonathanChan2020+MeowlWatch@u.northwestern.edu.", action: {
                    if let infoDictionary = Bundle.main.infoDictionary,
                        let versionString = infoDictionary["CFBundleShortVersionString"],
                        let url = URL(string: "mailto:Jonathan%20Chan%20at%20MeowlWatch%3cJonathanChan2020+MeowlWatch@u.northwestern.edu%3e?subject=MeowlWatch%20Feedback%20(v\(versionString))") {
                        UIApplication.shared.openURL(url)
                    }
                })
                tableView.deselectRow(at: indexPath, animated: true)

            case 1:
                self.performSegue(withIdentifier: "ShowLegal", sender: self)

            default:
                break
            }

        default:
            break
        }
    }

    #if !MEOWLWATCH_FULL
        /// Prompts the user to purchase the widget if `widgetProduct` is not nil, i.e., if it is available from the app store.
        func buyWidgetIfAvailable() {
            guard let widgetProduct = widgetProduct else { return }
            let payment = SKPayment(product: widgetProduct)
            SKPaymentQueue.default().add(payment)
            self.beginRefreshing()
        }

        /// Shows an alert to notify the user that we cannot make purchases.
        func showCannotMakePaymentsAlert() {
            self.endRefreshing()
            self.showMessageAlert(title: "Cannot Make Purchases", message: "Please go to Settings and configure your iTunes account, or enable In-App Purchases.")
        }

        var isRefreshing = false


        /// Makes the refresh control start refreshing, if it exists.
        func beginRefreshing() {
            guard let refreshControl = self.refreshControl else { return }
            isRefreshing = true
            refreshControl.beginRefreshing()
            if #available(iOS 11.0, *) {
                self.tableView.setContentOffset(CGPoint(x: 0, y: -self.tableView.adjustedContentInset.top), animated: true)
            } else {
                self.tableView.setContentOffset(CGPoint(x: 0, y: -self.tableView.contentInset.top), animated: true)
            }
        }

        /// Makes the refresh control stop spinning, if it exists.
        func endRefreshing() {
            guard let refreshControl = self.refreshControl else { return }
            isRefreshing = false
            DispatchQueue.main.async { [unowned refreshControl] in
                refreshControl.endRefreshing()
            }
        }
    #endif

}

#if !MEOWLWATCH_FULL
    extension SettingsTableViewController: SKProductsRequestDelegate {

        func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
            // Show list of available purchases
            for product in response.products {
                if product.productIdentifier == MeowlWatchData.widgetProductIdentifier {
                    self.widgetProduct = product
                }
            }
            self.tableView.reloadData()
            self.endRefreshing()
        }

        func request(_ request: SKRequest, didFailWithError error: Error) {
            self.showMessageAlert(title: "Unable to Fetch In-App Purchases", message: "Please try again later.", completion: { [unowned self] in
                self.tableView.reloadData()
                self.endRefreshing()
            })
        }

        /// Query the app store for the IAPs.
        @objc func requestProductData() {
            guard SKPaymentQueue.canMakePayments() else {
                return
            }
            if let refreshControl = refreshControl, !refreshControl.isRefreshing {
                self.beginRefreshing()
            }
            self.canMakePayments = true
            let request = SKProductsRequest(productIdentifiers: [MeowlWatchData.widgetProductIdentifier])
            request.delegate = self
            request.start()
            self.tableView.reloadData()
        }

        /// What to do once the widget is purchased.
        func didPurchaseWidget() {
            SKPaymentQueue.default().remove(self)
            self.showMessageAlert(title: "Thank you for your support!", message: "It may take a minute for the widget to be enabled.")

            self.tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentInset.top), animated: true)
            self.endRefreshing()
            self.refreshControl!.removeFromSuperview()

            MeowlWatchData.widgetIsPurchased = true
            let navigationController = self.navigationController as! NavigationController
            navigationController.bannerView = nil
            navigationController.setToolbarHidden(true, animated: false)
            self.tableView.reloadData()
        }

    }

    extension SettingsTableViewController: SKPaymentTransactionObserver {

        func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
            // Maybe user purchased
            for transaction in transactions {
                handleTransaction(transaction, withQueue: queue)
            }
        }

        func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
            for transaction in queue.transactions {
                if transaction.transactionState == .purchased || transaction.transactionState == .restored {
                    handleTransaction(transaction, withQueue: queue)
                } else if transaction.transactionState == .failed {
                    queue.finishTransaction(transaction)
                }
            }

            if !MeowlWatchData.widgetIsPurchased {
                self.showMessageAlert(title: "Unable To Restore Purchases", message: "No previous purchases could be found.")
                self.endRefreshing()
            }
        }

        func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
            self.showMessageAlert(title: "Unable To Restore Purchases", message: "Please try again later.")
            self.endRefreshing()
        }

        /// What to do once we receive a transaction.
        /// - Parameter transaction: The StoreKit transaction.
        /// - Parameter queue: The StoreKit payment queue.
        func handleTransaction(_ transaction: SKPaymentTransaction, withQueue queue: SKPaymentQueue) {
            switch transaction.transactionState {
            case .purchased, .restored:
                self.endRefreshing()
                if transaction.payment.productIdentifier == MeowlWatchData.widgetProductIdentifier {
                    didPurchaseWidget()
                    queue.finishTransaction(transaction)
                }

            case .failed:
                self.endRefreshing()
                self.showMessageAlert(title: "Unable To Purchase", message: "Please try again.")
                queue.finishTransaction(transaction)

            default:
                break
            }
        }

    }
#endif
