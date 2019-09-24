//
//  SettingsTableViewController.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-03-23.
//  Copyright © 2018 Jonathan Chan. All rights reserved.
//

import UIKit
import MeowlWatchData
import MessageUI
import SafariServices

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
    let isabelURLString = "https://www.instagram.com/koalatydoodles"

    /// Shortened URL for designer's website.
    /// TODO: use a URL tracker or something.
    var isabelShortURLString: String { return isabelURLString }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        self.setEditing(true, animated: false)

        tableView.register(UINib(nibName: "WidgetPreviewTableViewCell", bundle: nil), forCellReuseIdentifier: "WidgetPreviewCell")

        #if !MEOWLWATCH_FULL
            if !MeowlWatchData.anythingIsPurchased {
                requestProductData()
            }
            SKPaymentQueue.default().add(self)
        #endif

        navigationItem.largeTitleDisplayMode = .never

        setCanDismiss(true, animated: false)
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

        if currentLanguage != selectedLanguage {
            currentLanguage = selectedLanguage
            let delegate = UIApplication.shared.delegate as? AppDelegate
            delegate?.reloadRootVC()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return MeowlWatchData.widgetArrangement.count
        case 1:
            if MeowlWatchData.removeAdsIsPurchased {
                return 1
            } else {
                return 2
            }
        case 2:
            return 1
        case 3:
            return languages.count
        case 4:
            return 4
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return mwLocalizedString("SettingsWidgetHeading", comment: "Widget")
        case 1:
            return mwLocalizedString("SettingsRemoveAdsHeading", comment: "Support MeowlWatch")
        case 2:
            return mwLocalizedString("SettingsLogoHeading", comment: "Logo")
        case 3:
            return mwLocalizedString("SettingsLanguageTitle")
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        // Configure the cell...
        switch indexPath.section {
        case 0:
            cell = tableView.dequeueReusableCell(withIdentifier: "WidgetArrangementCell", for: indexPath)

            let item = MeowlWatchData.widgetArrangement[indexPath.row]
            cell!.textLabel!.text = QueryResult.description(forItem: item, withQuery: nil)
        case 1:
            switch indexPath.row {
            case 0:
                if MeowlWatchData.removeAdsIsPurchased {
                    cell = tableView.dequeueReusableCell(withIdentifier: "ThanksForTipCell", for: indexPath)
                    cell!.textLabel!.text = mwLocalizedString("SettingsRemoveAdsAlreadyPurchased", comment: "Remove Ads Purchased!")
                } else if isRefreshing {
                    cell = tableView.dequeueReusableCell(withIdentifier: "LoadingButtonCell", for: indexPath)
                    cell!.textLabel!.text = mwLocalizedString("SettingsLoadingTitle", comment: "")
                } else {
                    cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath)
                    if let widgetProduct = widgetProduct {
                        cell!.textLabel!.text = widgetProduct.localizedTitle
                    } else {
                        cell!.textLabel!.text = mwLocalizedString("SettingsIAPUnavailableTitle", comment: "")
                    }
                }

            case 1:
                cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath)
                cell!.textLabel!.text = mwLocalizedString("SettingsRestorePurchasesTitle", comment: "")

            default:
                break
            }

        case 2:
            cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath)
            cell!.textLabel!.text = mwLocalizedString("SettingsVisitDesignerWebsiteTitle", comment: "")

        case 3:
            cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            let language = languages[indexPath.row]
            if language == .default {
                cell?.textLabel?.text = String(format: NSLocalizedString("SettingsLanguageDefault: %@", comment: ""), NSLocale(localeIdentifier: systemDefaultLanguage().rawValue).displayName(forKey: .languageCode, value: systemDefaultLanguage().rawValue) ?? "--")
                cell?.detailTextLabel?.text = currentLanguage != .default ? mwLocalizedString("SettingsLanguageDefault") : nil
            } else {
                cell?.textLabel?.text = mwLocalizedString("SettingsLanguage_\(language.rawValue)")
            }
            cell?.accessoryType = language == selectedLanguage ? .checkmark : .none

        case 4:
            cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath)
            switch indexPath.row {
            case 0:
                cell!.textLabel!.text = mwLocalizedString("SettingsSendFeedbackTitle", comment: "")
            case 1:
                cell!.textLabel!.text = mwLocalizedString("SettingsRateOnAppStoreTitle", comment: "")
            case 2:
                cell!.textLabel?.text = mwLocalizedString("SettingsContributeTitle")
            case 3:
                cell!.textLabel!.text = mwLocalizedString("SettingsShowLegalTitle", comment: "")
            default:
                break
            }
            
        default:
            break
        }

        return cell!
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            return mwLocalizedString("SettingsWidgetHelpMessage", comment: "")
        case 1:
            if !MeowlWatchData.removeAdsIsPurchased {
                return mwLocalizedString("SettingsTipInfoMessage", comment: "This is what the tip does.")
            } else {
                return mwLocalizedString("SettingsTipThankMessage", comment: "Thank you for your support!")
            }
        case 2:
            return String(format: mwLocalizedString("SettingsArtistInfoMessage: %@", comment: ""), isabelURLString)
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
            return true
        default:
            return false
        }
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

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            if !MeowlWatchData.removeAdsIsPurchased {
                if !isRefreshing {
                    switch indexPath.row {
                    case 0:
                        if canMakePayments {
                            if widgetProduct != nil {
                                buyWidgetIfAvailable()
                            } else {
                                self.showMessageAlert(title: mwLocalizedString("SettingsIAPUnavailableTitle", comment: ""), message: mwLocalizedString("SettingsIAPUnavailableMessage", comment: ""))
                            }
                        } else {
                            showCannotMakePaymentsAlert()
                        }

                    case 1:
                        setCanDismiss(false, animated: true)
                        SKPaymentQueue.default().restoreCompletedTransactions()

                    default:
                        break
                    }
                }
                tableView.deselectRow(at: indexPath, animated: true)
            }

        case 2:
            guard let url = URL(string: self.isabelShortURLString) else { return }
            let safariVC = SFSafariViewController(url: url)
            safariVC.preferredControlTintColor = self.view.tintColor
            self.present(safariVC, animated: true, completion: nil)
            tableView.deselectRow(at: indexPath, animated: true)

        case 3:
            let previousLanguage = selectedLanguage
            selectedLanguage = languages[indexPath.row]
            tableView.reloadRows(at: [indexPath, IndexPath(row: languages.firstIndex(of: previousLanguage)!, section: indexPath.section)], with: .none)
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            tableView.deselectRow(at: indexPath, animated: true)

        case 4:
            switch indexPath.row {
            case 0:
                let emailAddress = "JonathanChan2020+MeowlWatch@u.northwestern.edu"
                let alertController = UIAlertController(title: mwLocalizedString("SettingsSendFeedbackTitle", comment: ""), message: String(format: mwLocalizedString("SettingsSendFeedbackInfoMessage: %@", comment: ""), emailAddress), preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: mwLocalizedString("SettingsCopyEmailActionTitle", comment: ""), style: .default) { _ in
                    UIPasteboard.general.setValue(emailAddress, forPasteboardType: UIPasteboard.typeListString.firstObject as! String)
                })
                if MFMailComposeViewController.canSendMail() {
                    alertController.addAction(UIAlertAction(title: mwLocalizedString("SettingsOpenInMailActionTitle", comment: ""), style: .default) { [weak self] _ in
                        guard self != nil else { return }
                        let composeVC = MFMailComposeViewController()
                        let versionString = Bundle.main.infoDictionary!["CFBundleShortVersionString"]!
                        composeVC.setToRecipients([emailAddress])
                        composeVC.setSubject(String(format: mwLocalizedString("SettingsFeedbackSubject: %@", comment: ""), "\(versionString)"))
                        composeVC.view.tintColor = self!.view.tintColor
                        composeVC.mailComposeDelegate = self!
                        self!.present(composeVC, animated: true, completion: nil)
                    })
                }
                alertController.addAction(UIAlertAction(title: mwLocalizedString("SettingsFeedbackDoneButtonTitle", comment: ""), style: .cancel, handler: nil))
                alertController.view.tintColor = view.tintColor
                present(alertController, animated: true, completion: nil)
                tableView.deselectRow(at: indexPath, animated: true)

            case 1:
                UIApplication.shared.open(URL(string: rateOnAppStoreUrl)!)
                tableView.deselectRow(at: indexPath, animated: true)

            case 2:
                UIApplication.shared.open(URL(string: githubUrl)!)
                tableView.deselectRow(at: indexPath, animated: true)

            case 3:
                self.performSegue(withIdentifier: "ShowLegal", sender: self)

            default:
                break
            }

        default:
            break
        }
    }

    lazy var doneButton: UIBarButtonItem = {
        let doneButton = UIBarButtonItem(title: mwLocalizedString("SettingsDoneButton", comment: "Done"), style: .done, target: self, action: #selector(dismiss as () -> Void))
        return doneButton
    }()

    func setCanDismiss(_ canDismiss: Bool, animated: Bool) {
        navigationItem.setRightBarButton(canDismiss ? doneButton : nil, animated: animated)
        if #available(iOS 13.0, *) {
            isModalInPresentation = !canDismiss
        }
    }

    /// Dismisses this VC.
    @objc
    func dismiss() {
        navigationController!.dismiss(animated: true, completion: nil)
    }

    #if !MEOWLWATCH_FULL
        /// Prompts the user to purchase the widget if `widgetProduct` is not nil, i.e., if it is available from the app store.
        func buyWidgetIfAvailable() {
            guard let widgetProduct = widgetProduct else { return }
            let payment = SKPayment(product: widgetProduct)
            SKPaymentQueue.default().add(payment)
            setCanDismiss(false, animated: true)
        }

        /// Shows an alert to notify the user that we cannot make purchases.
        func showCannotMakePaymentsAlert() {
            self.showMessageAlert(title: mwLocalizedString("SettingsCannotPayAlertTitle", comment: ""), message: mwLocalizedString("SettingsCannotPayAlertMessage", comment: ""))
            isRefreshing = false
            setCanDismiss(true, animated: false)
        }

        var isRefreshing = true


    #endif

}

extension SettingsTableViewController: MFMailComposeViewControllerDelegate {

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }

}

#if !MEOWLWATCH_FULL
    extension SettingsTableViewController: SKProductsRequestDelegate {

        func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
            // Show list of available purchases
            for product in response.products {
                if product.productIdentifier == MeowlWatchData.removeAdsProductIdentifier {
                    self.widgetProduct = product
                }
            }
            DispatchQueue.main.async { [weak self] in
                self?.isRefreshing = false
                self?.setCanDismiss(true, animated: false)
                self?.tableView?.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .none)
            }
        }

        func request(_ request: SKRequest, didFailWithError error: Error) {
            DispatchQueue.main.async { [weak self] in
                self?.showMessageAlert(title: mwLocalizedString("SettingsCannotFetchAlertTitle", comment: ""), message: mwLocalizedString("SettingsCannotFetchAlertMessage", comment: ""), completion: {
                        self?.isRefreshing = false
                    self?.setCanDismiss(true, animated: false)
                        self?.tableView?.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .none)
                })
            }
        }

        /// Query the app store for the IAPs.
        @objc func requestProductData() {
            guard SKPaymentQueue.canMakePayments() else {
                return
            }
            self.canMakePayments = true
            let request = SKProductsRequest(productIdentifiers: [MeowlWatchData.removeAdsProductIdentifier])
            request.delegate = self
            request.start()
        }

        /// What to do once the widget is purchased.
        func didPurchaseWidget() {
            SKPaymentQueue.default().remove(self)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.showMessageAlert(title: mwLocalizedString("SettingsThanksAlertTitle", comment: ""), message: mwLocalizedString("SettingsThanksAlertMessage", comment: ""))

                self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentInset.top), animated: true)
                self.isRefreshing = false
                self.setCanDismiss(true, animated: false)

                MeowlWatchData.removeAdsIsPurchased = true
                let navigationController = self.navigationController!.presentingViewController as! NavigationController
                navigationController.bannerView = nil
                navigationController.setToolbarHidden(true, animated: false)
                self.tableView.reloadData()
            }
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

            if !MeowlWatchData.removeAdsIsPurchased {
                DispatchQueue.main.async { [weak self] in
                    self?.showMessageAlert(title: mwLocalizedString("SettingsCannotRestorePurchaseAlertTitle", comment: ""), message: mwLocalizedString("SettingsCannotRestorePurchaseAlertMessage", comment: ""))
                    self?.isRefreshing = false
                    self?.setCanDismiss(true, animated: false)
                }
            }
        }

        func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
            DispatchQueue.main.async { [weak self] in
                self?.showMessageAlert(title: mwLocalizedString("SettingsRestorePurchaseFailedAlertTitle", comment: ""), message: mwLocalizedString("SettingsRestorePurchaseFailedAlertMessage", comment: ""))
                self?.isRefreshing = false
                self?.setCanDismiss(true, animated: false)
            }
        }

        /// What to do once we receive a transaction.
        /// - Parameter transaction: The StoreKit transaction.
        /// - Parameter queue: The StoreKit payment queue.
        func handleTransaction(_ transaction: SKPaymentTransaction, withQueue queue: SKPaymentQueue) {
            switch transaction.transactionState {
            case .purchased, .restored:
                DispatchQueue.main.async { [weak self] in
                    self?.isRefreshing = false
                    self?.setCanDismiss(true, animated: false)
                }
                if transaction.payment.productIdentifier == MeowlWatchData.removeAdsProductIdentifier {
                    didPurchaseWidget()
                    queue.finishTransaction(transaction)
                }

            case .failed:
                DispatchQueue.main.async { [weak self] in
                    self?.isRefreshing = false
                    self?.setCanDismiss(true, animated: false)
                    self?.showMessageAlert(title: mwLocalizedString("SettingsPurchaseFailedAlertTitle", comment: ""), message: mwLocalizedString("SettingsPurchaseFailedAlertMessage", comment: ""))
                }
                queue.finishTransaction(transaction)

            default:
                break
            }
        }

    }
#endif
