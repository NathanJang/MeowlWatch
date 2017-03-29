//
//  SettingsTableViewController.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-03-23.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import UIKit
import StoreKit

class SettingsTableViewController: UITableViewController {

    let widgetProductIdentifier = "MeowlWatch_Widget" // "MeowlWatch_Widget_Consumable"

    var widgetProduct: SKProduct?

    var isRequestingProducts = false {
        didSet {
            if isRequestingProducts { self.beginRefreshing() }
            else { self.endRefreshing() }
        }
    }

    var canMakePayments = false

    let isabelURLString = "https://isabel6389.wixsite.com/website"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        self.setEditing(true, animated: false)

        if !Datastore.widgetPurchased {
            self.refreshControl = UIRefreshControl()
            refreshControl!.addTarget(self, action: #selector(requestProductData), for: .valueChanged)
            SKPaymentQueue.default().add(self)
            requestProductData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !Datastore.widgetPurchased && !canMakePayments {
            showCannotMakePaymentsAlert()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        SKPaymentQueue.default().remove(self)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if Datastore.widgetPurchased {
                return 4
            } else {
                if isRequestingProducts {
                    return 2
                } else {
                    return 3
                }
            }
        case 1:
            return 1
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Widget Settings"
        case 1:
            return "Logo"
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        // Configure the cell...
        switch indexPath.section {
        case 0:
            if Datastore.widgetPurchased {
                cell = tableView.dequeueReusableCell(withIdentifier: "WidgetArrangementCell", for: indexPath)

                let item = Datastore.widgetArrangement[indexPath.row]
                cell.textLabel!.text = QueryResult.description(forItem: item, withQuery: nil)
            } else {
                switch indexPath.row {
                case 0:
                    if self.isRequestingProducts {
                        cell = tableView.dequeueReusableCell(withIdentifier: "LoadingButtonCell", for: indexPath)
                        cell.textLabel!.text = "Loading..."
                    } else {
                        cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath)
                        if let widgetProduct = widgetProduct {
                            cell.textLabel!.text = "Enable \(widgetProduct.localizedTitle) (\(self.localizedPrice(for: widgetProduct)))"
                        } else {
                            cell.textLabel!.text = "(In-App Purchase Unavailable)"
                        }
                    }
                case 1:
                    cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath)
                    cell.textLabel!.text = "Restore Purchases"

                case 2:
                    cell = tableView.dequeueReusableCell(withIdentifier: "WidgetPreviewCell", for: indexPath)

                default:
                    cell = tableView.dequeueReusableCell(withIdentifier: "LoadingButtonCell", for: indexPath)
                }
            }
        case 1:
            cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath)
            cell.textLabel!.text = "Visit Designer's Website"
            
        default:
            cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if !Datastore.widgetPurchased && indexPath == IndexPath(row: 2, section: 0) {
            let imageSize = #imageLiteral(resourceName: "WidgetPreviewFull").size
            return self.view.frame.width * imageSize.height / imageSize.width
        }

        return UITableViewAutomaticDimension
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            if Datastore.widgetPurchased {
                return "The MeowlWatch widget may be added to the Today View on the Notification Center. Your preferences here will be reflected on the widget."
            } else {
                return "Making useful apps like MeowlWatch is hard. Please consider supporting me by enabling the widget! Ads will also be disabled."
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
            return Datastore.widgetPurchased
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

    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        Datastore.moveWidgetArrangement(fromIndex: fromIndexPath.row, toIndex: to.row)
    }

    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        switch indexPath.section {
        case 0:
            return true
        default:
            return false
        }
    }

    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            let row = sourceIndexPath.section < proposedDestinationIndexPath.section ? tableView.numberOfRows(inSection: sourceIndexPath.section) - 1 : 0
            return IndexPath(row: row, section: sourceIndexPath.section)
        }

        return proposedDestinationIndexPath
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            if !Datastore.widgetPurchased {
                switch indexPath.row {
                case 0:
                    if canMakePayments {
                        buyWidget()
                    } else {
                        showCannotMakePaymentsAlert()
                    }

                case 1:
                    self.isRequestingProducts = true
                    SKPaymentQueue.default().restoreCompletedTransactions()

                default:
                    break
                }
            }

        case 1:
            let alertController = UIAlertController(title: "Open Designer's Website?", message: nil, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default) {action in
                let url = URL(string: self.isabelURLString)!
                UIApplication.shared.openURL(url)
            })
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)


        default:
            break
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    func buyWidget() {
        let payment = SKPayment(product: widgetProduct!)
        SKPaymentQueue.default().add(payment)
        self.isRequestingProducts = true
    }

    func showCannotMakePaymentsAlert() {
        self.isRequestingProducts = false
        let alertController = UIAlertController(title: "Cannot Make Purchases", message: "Please go to Settings and configure your iTunes account, or enable In-App Purchases.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    func beginRefreshing() {
        DispatchQueue.main.async {
            guard let refreshControl = self.refreshControl else { return }
            refreshControl.beginRefreshing()
            self.tableView.setContentOffset(CGPoint(x: 0, y: -self.tableView.contentInset.top), animated: true)
        }
    }

    func endRefreshing() {
        DispatchQueue.main.async {
            guard let refreshControl = self.refreshControl else { return }
            refreshControl.endRefreshing()
            self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentOffset.y + self.tableView.contentInset.top), animated: true)
        }
    }

}

extension SettingsTableViewController: SKProductsRequestDelegate {

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        // Show list of available purchases
        self.isRequestingProducts = false
        for product in response.products {
            if product.productIdentifier == widgetProductIdentifier {
                self.widgetProduct = product
            }
        }
        self.tableView.reloadData()
    }

    func localizedPrice(for product: SKProduct) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = product.priceLocale
        return numberFormatter.string(from: product.price)!
    }

    func requestProductData() {
        guard SKPaymentQueue.canMakePayments() else { return }
        self.isRequestingProducts = true
        self.canMakePayments = true
        let request = SKProductsRequest(productIdentifiers: [widgetProductIdentifier])
        request.delegate = self
        request.start()
    }

    func didPurchaseWidget() {
        let alertController = UIAlertController(title: "Thank you for your support!", message: "It may take a minute for the widget to be enabled.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)

        self.refreshControl!.removeFromSuperview()
        self.refreshControl = nil

        Datastore.widgetPurchased = true
        Datastore.persistToUserDefaults()
        let parentViewController = self.navigationController!.viewControllers[navigationController!.viewControllers.count - 2] as! TableViewController
        parentViewController.bannerView = nil
        parentViewController.navigationController!.setToolbarHidden(true, animated: false)
        self.tableView.reloadData()
    }

}

extension SettingsTableViewController: SKPaymentTransactionObserver {

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        // Maybe user purchased
        self.isRequestingProducts = false
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                if transaction.payment.productIdentifier == widgetProductIdentifier {
                    didPurchaseWidget()
                    queue.finishTransaction(transaction)
                }

            case .failed:
                let alertController = UIAlertController(title: "Unable To Purchase", message: "Please try again.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
                queue.finishTransaction(transaction)

            case .restored:
                if transaction.payment.productIdentifier == widgetProductIdentifier {
                    didPurchaseWidget()
                    queue.finishTransaction(transaction)
                }

            default:
                break
            }
        }
    }

    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        if !Datastore.widgetPurchased {
            let alertController = UIAlertController(title: "Unable To Restore Purchases", message: "No previous purchases could be found.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            self.isRequestingProducts = false
        }
    }

    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        let alertController = UIAlertController(title: "Unable To Restore Purchases", message: "Please try again.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

}
