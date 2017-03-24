//
//  FreeSettingsTableViewController.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-03-24.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import UIKit

class FreeSettingsTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 0 {
            // TODO: Link to page
        } else if indexPath.section == 2 {

        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell

        // Configure the cell...
        switch indexPath.section {
        case 0:
            cell = tableView.dequeueReusableCell(withIdentifier: "WebsiteButtonCell", for: indexPath)
            cell.textLabel!.text = "Full Version ($0.99) in App Store"
        case 1:
            cell = UITableViewCell()
            cell.isUserInteractionEnabled = false
            let imageView = UIImageView(image: #imageLiteral(resourceName: "WidgetPreviewFull"))
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleToFill
            cell.addSubview(imageView)
            cell.addConstraints([
                NSLayoutConstraint(item: imageView, attribute: .left, relatedBy: .equal, toItem: cell, attribute: .left, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: imageView, attribute: .top, relatedBy: .equal, toItem: cell, attribute: .top, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: imageView, attribute: .right, relatedBy: .equal, toItem: cell, attribute: .right, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: imageView, attribute: .bottom, relatedBy: .equal, toItem: cell, attribute: .bottom, multiplier: 1, constant: 0)
            ])
        case 2:
            cell = tableView.dequeueReusableCell(withIdentifier: "WebsiteButtonCell", for: indexPath)
            cell.textLabel!.text = "Visit Designer's Website"
        default:
            cell = tableView.dequeueReusableCell(withIdentifier: "WebsiteButtonCell", for: indexPath)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath == IndexPath(row: 0, section: 1) {
            let imageSize = #imageLiteral(resourceName: "WidgetPreviewFull").size
            return imageSize.height * tableView.contentSize.width / imageSize.width
        } else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Full Version"
        case 2:
            return "Logo"
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Developing useful apps like MeowlWatch is hard work. Please consider supporting me by buying the full version, which includes more features like a Notification Center widget. Support through Venmo is also appreciated @jonchanyc."
        case 2:
            return "The MeowlWatch logo was designed by Isabel Nygard. Visit http://example.com to see more."
        default:
            return nil
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

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

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
