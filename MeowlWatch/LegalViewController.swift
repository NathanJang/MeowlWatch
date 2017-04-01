//
//  LegalViewController.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-03-29.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import UIKit

/// The view controller displaying a text view with legal text.
class LegalViewController: UIViewController {

    /// The text view.
    @IBOutlet weak var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        textView.contentInset = UIEdgeInsets.zero
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        textView.scrollIndicatorInsets = UIEdgeInsets.zero

        textView.setContentOffset(CGPoint.zero, animated: false)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
