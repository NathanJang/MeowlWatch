//
//  TodayViewController.swift
//  MeowlWatch Widget
//
//  Created by Jonathan Chan on 2017-03-22.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {

    @IBOutlet weak var leftNumberLabel: UILabel!
    @IBOutlet weak var leftDescriptionLabel: UILabel!
    @IBOutlet weak var rightNumberLabel: UILabel!
    @IBOutlet weak var rightDescriptionLabel: UILabel!
    @IBOutlet weak var secondaryLeftNumberLabel: UILabel!
    @IBOutlet weak var secondaryLeftDescriptionLabel: UILabel!
    @IBOutlet weak var secondaryRightNumberLabel: UILabel!
    @IBOutlet weak var secondaryRightDescriptionLabel: UILabel!

    /// A flag representing whether this is the widget's initial setup.
    /// Once the widget performs an update for the first time, this will be set to `false`.
    var isFirstRun = true
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        Datastore.loadFromDefaults()
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
        guard !isFirstRun else {
            updateLabels(with: Datastore.lastQuery)
            isFirstRun = false
            return completionHandler(.newData)
        }
        guard Datastore.shouldRefresh else {
            updateLabels(with: Datastore.lastQuery)
            return completionHandler(.noData)
        }
        guard Datastore.canQuery else {
            updateLabels(with: Datastore.lastQuery)
            return completionHandler(.failed)
        }
        Datastore.query {result in
            self.updateLabels(with: result)
            completionHandler(.newData)
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
    func updateLabels(with query: QueryResult?) {
        leftDescriptionLabel.text = QueryResult.description(forItem: Datastore.widgetArrangement[0], withQuery: query)
        rightDescriptionLabel.text = QueryResult.description(forItem: Datastore.widgetArrangement[1], withQuery: query)
        secondaryLeftDescriptionLabel.text = QueryResult.description(forItem: Datastore.widgetArrangement[2], withQuery: query)
        secondaryRightDescriptionLabel.text = QueryResult.description(forItem: Datastore.widgetArrangement[3], withQuery: query)

        if let query = query {
            updateNumberLabel(leftNumberLabel, asItem: Datastore.widgetArrangement[0], withQuery: query)
            updateNumberLabel(rightNumberLabel, asItem: Datastore.widgetArrangement[1], withQuery: query)
            updateNumberLabel(secondaryLeftNumberLabel, asItem: Datastore.widgetArrangement[2], withQuery: query)
            updateNumberLabel(secondaryRightNumberLabel, asItem: Datastore.widgetArrangement[3], withQuery: query)
        }
    }

    /// Sets the content of a number label given a desired widget item and a query result object.
    /// - Parameter label: The number label.
    /// - Parameter item: The widget item type.
    /// - Parameter query: The query result to use.
    func updateNumberLabel(_ label: UILabel, asItem item: QueryResult.DisplayItem, withQuery query: QueryResult) {
        DispatchQueue.main.async {
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

}
