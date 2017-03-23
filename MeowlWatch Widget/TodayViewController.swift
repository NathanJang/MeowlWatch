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

    var leftItem: Datastore.WidgetItem?
    var rightItem: Datastore.WidgetItem?

    var isFirstRun = true
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        Datastore.loadFromDefaults()
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
        /*
        if let lastQuery = Datastore.lastQuery {
            guard !isFirstRun else {
                updateLabels(with: lastQuery)
                self.isFirstRun = false
                return completionHandler(.newData)
            }
            // Only update after 30 minutes
            guard Datastore.shouldRefresh else {
                return completionHandler(.noData)
            }
        }
        guard Datastore.canQuery else {
            updateLabels(with: nil)
            return completionHandler(.failed)
        }
        Datastore.query {result in
            self.updateLabels(with: result)

            Datastore.persistToUserDefaults()

            completionHandler(.newData)
        }

        //guard let lastQuery = Datastore.lastQuery else {

        //}
         */
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

    func updateLabels(with query: QueryResult?) {
        leftDescriptionLabel.text = Datastore.stringForWidgetItem(Datastore.widgetArrangement[0])
        rightDescriptionLabel.text = Datastore.stringForWidgetItem(Datastore.widgetArrangement[1])

        if let query = query {
            switch Datastore.widgetArrangement[0] {
            case .boardMeals:
                self.leftNumberLabel.text = query.boardMeals
            case .equivalencyMeals:
                self.leftNumberLabel.text = query.equivalencyMeals
            case .points:
                self.leftNumberLabel.text = query.points
            case .catCash:
                self.leftNumberLabel.text = query.totalCatCash
            }

            switch Datastore.widgetArrangement[1] {
            case .boardMeals:
                self.rightNumberLabel.text = query.boardMeals
            case .equivalencyMeals:
                self.rightNumberLabel.text = query.equivalencyMeals
            case .points:
                self.rightNumberLabel.text = query.points
            case .catCash:
                self.rightNumberLabel.text = query.totalCatCash
            }
        }
    }

}
