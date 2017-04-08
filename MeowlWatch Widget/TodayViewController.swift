//
//  TodayViewController.swift
//  MeowlWatch Widget
//
//  Created by Jonathan Chan on 2017-03-22.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import UIKit
import NotificationCenter
import MeowlWatchData

class TodayViewController: UIViewController, NCWidgetProviding {

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
            self.extensionContext!.widgetLargestAvailableDisplayMode = .expanded
        } else {
            // Fallback on earlier versions
            self.preferredContentSize = CGSize(width: preferredContentSize.width, height: 220)
            let descriptionColor = UIColor.white
            leftDescriptionLabel.textColor = descriptionColor
            rightDescriptionLabel.textColor = descriptionColor
            secondaryLeftDescriptionLabel.textColor = descriptionColor
            secondaryRightDescriptionLabel.textColor = descriptionColor
            purchaseRequiredLabel.textColor = descriptionColor
            updatedLabel.textColor = descriptionColor
        }
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
        purchaseRequiredLabel.isHidden = true
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
        MeowlWatchData.query { queryResult in
            self.updateLabels(with: queryResult) {
                completionHandler(.newData)
            }
        }

    }

    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        UIView.animate(withDuration: 0.25) {
            if activeDisplayMode == .expanded {
                self.preferredContentSize = CGSize(width: maxSize.width, height: 220)
            } else {
                self.preferredContentSize = maxSize
            }
        }
    }

    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }

    /// Sets the label text to the appropriate content given a query result.
    /// - Parameter query: The query result.
    func updateLabels(with query: QueryResult?, onCompletion: (@escaping () -> Void)) {
        guard MeowlWatchData.widgetIsPurchased else { return }
        DispatchQueue.main.async {
            self.leftDescriptionLabel.text = QueryResult.description(forItem: MeowlWatchData.widgetArrangement[0], withQuery: query)
            self.rightDescriptionLabel.text = QueryResult.description(forItem: MeowlWatchData.widgetArrangement[1], withQuery: query)
            self.secondaryLeftDescriptionLabel.text = QueryResult.description(forItem: MeowlWatchData.widgetArrangement[2], withQuery: query)
            self.secondaryRightDescriptionLabel.text = QueryResult.description(forItem: MeowlWatchData.widgetArrangement[3], withQuery: query)

            if let query = query {
                self.updateNumberLabel(self.leftNumberLabel, asItem: MeowlWatchData.widgetArrangement[0], withQuery: query)
                self.updateNumberLabel(self.rightNumberLabel, asItem: MeowlWatchData.widgetArrangement[1], withQuery: query)
                self.updateNumberLabel(self.secondaryLeftNumberLabel, asItem: MeowlWatchData.widgetArrangement[2], withQuery: query)
                self.updateNumberLabel(self.secondaryRightNumberLabel, asItem: MeowlWatchData.widgetArrangement[3], withQuery: query)

                self.updatedLabel.text = "Updated: \(query.dateUpdatedString ?? "Never")"
            }

            onCompletion()
        }
    }

    /// Sets the content of a number label given a desired widget item and a query result object.
    /// - Parameter label: The number label.
    /// - Parameter item: The widget item type.
    /// - Parameter query: The query result to use.
    func updateNumberLabel(_ label: UILabel, asItem item: QueryResult.DisplayItem, withQuery query: QueryResult) {
        switch item {
        case .boardMeals:
            label.text = query.boardMeals
        case .equivalencyMeals:
            label.text = query.equivalencyMeals
        case .points:
            label.text = query.points
        case .catCash:
            label.text = query.totalCatCash
        }
    }

}
