//
//  WidgetViewController.swift
//  MeowlWatch Widget
//
//  Created by Jonathan Chan on 2017-03-22.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import UIKit
import NotificationCenter
import MeowlWatchData

class WidgetViewController: UIViewController, NCWidgetProviding {

    @IBOutlet weak var leftNumberLabel: UILabel!
    @IBOutlet weak var leftDescriptionLabel: UILabel!
    @IBOutlet weak var rightNumberLabel: UILabel!
    @IBOutlet weak var rightDescriptionLabel: UILabel!
    @IBOutlet weak var secondaryLeftNumberLabel: UILabel!
    @IBOutlet weak var secondaryLeftDescriptionLabel: UILabel!
    @IBOutlet weak var secondaryRightNumberLabel: UILabel!
    @IBOutlet weak var secondaryRightDescriptionLabel: UILabel!
    @IBOutlet weak var purchaseRequiredLabel: UILabel!
    @IBOutlet weak var updatedLabel: UILabel!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        if #available(iOSApplicationExtension 10.0, *) {
            if let extensionContext = extensionContext {
                extensionContext.widgetLargestAvailableDisplayMode = .expanded
            }
        } else {
            // Fallback on earlier versions
            self.preferredContentSize = CGSize(width: self.preferredContentSize.width, height: 220)
            let descriptionColor = UIColor.white
            self.leftDescriptionLabel.textColor = descriptionColor
            self.rightDescriptionLabel.textColor = descriptionColor
            self.secondaryLeftDescriptionLabel.textColor = descriptionColor
            self.secondaryRightDescriptionLabel.textColor = descriptionColor
            self.purchaseRequiredLabel.textColor = descriptionColor
            self.updatedLabel.textColor = descriptionColor
        }

        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapView(sender:))))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        MeowlWatchData.loadFromDefaults()

        guard MeowlWatchData.widgetIsPurchased else { return completionHandler(.noData) }
        self.purchaseRequiredLabel.isHidden = true
        guard MeowlWatchData.shouldRefresh else {
            updateLabels(with: MeowlWatchData.lastQuery) {
                completionHandler(.noData)
            }
            return
        }
        guard MeowlWatchData.canQuery else {
            updateLabels(with: MeowlWatchData.lastQuery) {
                completionHandler(.failed)
            }
            return
        }
        updateLabels(with: MeowlWatchData.lastQuery, onCompletion: nil)
        MeowlWatchData.query { [unowned self] queryResult in
            DispatchQueue.main.async {
                self.updateLabels(with: queryResult) {
                    completionHandler(.newData)
                }
            }
        }

    }

    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .expanded {
            self.preferredContentSize = CGSize(width: maxSize.width, height: 220)
        } else {
            self.preferredContentSize = maxSize
        }
    }

    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }

    /// Sets the label text to the appropriate content given a query result.
    /// - Parameter query: The query result.
    func updateLabels(with query: QueryResult?, onCompletion: (() -> Void)?) {
        guard MeowlWatchData.widgetIsPurchased else { return }
            self.leftDescriptionLabel.text = QueryResult.description(forItem: MeowlWatchData.widgetArrangement[0], withQuery: query)
            self.rightDescriptionLabel.text = QueryResult.description(forItem: MeowlWatchData.widgetArrangement[1], withQuery: query)
            self.secondaryLeftDescriptionLabel.text = QueryResult.description(forItem: MeowlWatchData.widgetArrangement[2], withQuery: query)
            self.secondaryRightDescriptionLabel.text = QueryResult.description(forItem: MeowlWatchData.widgetArrangement[3], withQuery: query)

            if let query = query {
                self.updateNumberLabel(self.leftNumberLabel, asItem: MeowlWatchData.widgetArrangement[0], withQuery: query)
                self.updateNumberLabel(self.rightNumberLabel, asItem: MeowlWatchData.widgetArrangement[1], withQuery: query)
                self.updateNumberLabel(self.secondaryLeftNumberLabel, asItem: MeowlWatchData.widgetArrangement[2], withQuery: query)
                self.updateNumberLabel(self.secondaryRightNumberLabel, asItem: MeowlWatchData.widgetArrangement[3], withQuery: query)

                self.updatedLabel.text = "\(QueryResult.dateRetrievedDescription): \(query.dateRetrievedString)"
            }

            onCompletion?()
    }

    /// Sets the content of a number label given a desired widget item and a query result object.
    /// - Parameter label: The number label.
    /// - Parameter item: The widget item type.
    /// - Parameter query: The query result to use.
    func updateNumberLabel(_ label: UILabel, asItem item: QueryResult.WidgetDisplayItem, withQuery query: QueryResult) {
        switch item {
        case .boardMeals:
            label.text = query.boardMeals
        case .equivalencyMeals:
            label.text = query.equivalencyMeals
        case .points:
            label.text = query.points
        case .catCash:
            label.text = query.catCash
        case .equivalencyExchangeRate:
            label.text = MeowlWatchData.equivalencyExchangeRateString(at: Date())
        }
    }

    /// What to do when the gesture recognizer gets a tap.
    /// - Parameter sender: The gesture recognizer.
    func didTapView(sender: UITapGestureRecognizer) {
        guard let extensionContext = extensionContext,
            let url = URL(string: "meowlwatch://")
        else { return }
        if sender.state == .ended {
            extensionContext.open(url, completionHandler: nil)
        }
    }

}
