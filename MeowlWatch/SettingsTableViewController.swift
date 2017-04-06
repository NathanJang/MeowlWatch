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

        /// Whether we are currently performing some task, to show or hide the spinner.
        var isLoading = false {
            didSet {
                if isLoading { self.beginRefreshing() }
                else { self.endRefreshing() }
            }
        }

        /// Whether StoreKit can make payments, set before querying the app store.
        var canMakePayments = false
    #endif

    /// The logo designer's website's URL.
    let isabelURLString = "https://isabel6389.wixsite.com/website"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        self.setEditing(true, animated: false)

        #if !MEOWLWATCH_FULL
            if !MeowlWatchData.anythingIsPurchased {
                self.refreshControl = UIRefreshControl()
                refreshControl!.addTarget(self, action: #selector(requestProductData), for: .valueChanged)
                SKPaymentQueue.default().add(self)
                requestProductData()
            }
        #endif
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
                return 4
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
                        if self.isLoading {
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
                return "The MeowlWatch widget may be added to the Today View on the Notification Center. Your preferences here will be reflected on the widget."
            } else {
                return "Making useful apps like MeowlWatch is hard work. Please consider supporting me by enabling the widget! :) Ads will also be disabled."
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
        MeowlWatchData.persistToUserDefaults()
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            if !MeowlWatchData.widgetIsPurchased {
                #if !MEOWLWATCH_FULL
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
                        self.isLoading = true
                        SKPaymentQueue.default().restoreCompletedTransactions()

                    default:
                        break
                    }
                #endif
            }

        case 1:
            self.showActionPrompt(title: "Open Isabel Nygard's Website?", message: "Isabel Nygard is a Northwestern undergraduate student studying Art Theory & Practice and Materials Science & Engineering.") {
                let url = URL(string: self.isabelURLString)!
                UIApplication.shared.openURL(url)
            }

        case 2:
            switch indexPath.row {
            case 0:
                self.showActionPrompt(title: "Open Email App?", message: "Please send feedback to JonathanChan2020+MeowlWatch@u.northwestern.edu.") {
                    let url = URL(string: "mailto:Jonathan%20Chan%20at%20MeowlWatch%3cJonathanChan2020+MeowlWatch@u.northwestern.edu%3e?subject=MeowlWatch%20Feedback%20(v\(Bundle.main.infoDictionary!["CFBundleShortVersionString"]!))")!
                    UIApplication.shared.openURL(url)
                }

            case 1:
                self.performSegue(withIdentifier: "ShowLegal", sender: self)

            default:
                break
            }

        default:
            break
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    #if !MEOWLWATCH_FULL
        /// Prompts the user to purchase the widget if `widgetProduct` is not nil, i.e., if it is available from the app store.
        func buyWidgetIfAvailable() {
            guard let widgetProduct = widgetProduct else { return }
            let payment = SKPayment(product: widgetProduct)
            SKPaymentQueue.default().add(payment)
            self.isLoading = true
        }

        /// Shows an alert to notify the user that we cannot make purchases.
        func showCannotMakePaymentsAlert() {
            self.isLoading = false
            self.showMessageAlert(title: "Cannot Make Purchases", message: "Please go to Settings and configure your iTunes account, or enable In-App Purchases.")
        }


        /// Makes the refresh control start refreshing, if it exists.
        func beginRefreshing() {
            DispatchQueue.main.async {
                guard let refreshControl = self.refreshControl else { return }
                refreshControl.beginRefreshing()
                self.tableView.setContentOffset(CGPoint(x: 0, y: -self.tableView.contentInset.top), animated: true)
            }
        }

        /// Makes the refresh control stop spinning, if it exists.
        func endRefreshing() {
            DispatchQueue.main.async {
                guard let refreshControl = self.refreshControl else { return }
                refreshControl.endRefreshing()
                if self.tableView.contentOffset.y < 0 {
                    self.tableView.setContentOffset(CGPoint(x: 0, y: -self.tableView.contentInset.top), animated: true)
                }
            }
        }
    #endif

}

#if !MEOWLWATCH_FULL
    extension SettingsTableViewController: SKProductsRequestDelegate {

        func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
            // Show list of available purchases
            self.isLoading = false
            for product in response.products {
                if product.productIdentifier == MeowlWatchData.widgetProductIdentifier {
                    self.widgetProduct = product
                }
            }
            self.tableView.reloadData()
        }

        func request(_ request: SKRequest, didFailWithError error: Error) {
            self.showMessageAlert(title: "Unable to Fetch In-App Purchases", message: "Please try again later.")
            self.isLoading = false
            self.tableView.reloadData()
        }

        /// The localized string for the price of a product.
        /// - Parameter product: The StoreKit product.
        /// - Returns: A localized string for the product's price.
        func localizedPrice(for product: SKProduct) -> String {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .currency
            numberFormatter.locale = product.priceLocale
            return numberFormatter.string(from: product.price)!
        }

        /// Query the app store for the IAPs.
        func requestProductData() {
            guard SKPaymentQueue.canMakePayments() else {
                return
            }
            self.isLoading = true
            self.canMakePayments = true
            let request = SKProductsRequest(productIdentifiers: [MeowlWatchData.widgetProductIdentifier])
            request.delegate = self
            request.start()
            self.tableView.reloadData()
        }

        /// What to do once the widget is purchased.
        func didPurchaseWidget() {
            self.showMessageAlert(title: "Thank you for your support!", message: "It may take a minute for the widget to be enabled.")

            self.isLoading = false
            self.tableView.setContentOffset(CGPoint.zero, animated: true)
            DispatchQueue.main.async {
                self.refreshControl!.removeFromSuperview()
            }

            MeowlWatchData.widgetIsPurchased = true
            MeowlWatchData.persistToUserDefaults()
            let navigationController = self.navigationController as! NavigationController
            navigationController.bannerView = nil
            navigationController.navigationController!.setToolbarHidden(true, animated: false)
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
                if transaction.transactionState == .restored {
                    didPurchaseWidget()
                    queue.finishTransaction(transaction)
                }
            }

            if !MeowlWatchData.widgetIsPurchased {
                self.showMessageAlert(title: "Unable To Restore Purchases", message: "No previous purchases could be found.")
                self.isLoading = false
            }
        }

        func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
            self.showMessageAlert(title: "Unable To Restore Purchases", message: "Please try again later.")
            self.isLoading = false
        }

        /// What to do once we receive a transaction.
        /// - Parameter transaction: The StoreKit transaction.
        /// - Parameter queue: The StoreKit payment queue.
        func handleTransaction(_ transaction: SKPaymentTransaction, withQueue queue: SKPaymentQueue) {
            switch transaction.transactionState {
            case .purchased, .restored:
                self.isLoading = false
                if transaction.payment.productIdentifier == MeowlWatchData.widgetProductIdentifier {
                    didPurchaseWidget()
                    queue.finishTransaction(transaction)
                }

            case .failed:
                self.isLoading = false
                self.showMessageAlert(title: "Unable To Purchase", message: "Please try again.")
                queue.finishTransaction(transaction)

            default:
                break
            }
        }

    }
#endif
