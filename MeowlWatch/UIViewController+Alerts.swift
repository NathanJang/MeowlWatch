//
//  UIViewController+Alerts.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-04-04.
//  Copyright © 2018 Jonathan Chan. All rights reserved.
//

import UIKit

extension UIViewController {

    /// Prompts the user whether to perform an action.
    /// - Paramter title: The title of the alert controller.
    /// - Parameter message: The message in the alert controller.
    /// - Parameter action: The action to perform if the user chooses.
    func showActionPrompt(title: String, message: String?, action: (() -> Void)?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Go", style: .default) { _ in action?() })
        self.present(alertController, animated: true, completion: nil)
        alertController.view.tintColor = self.view.tintColor
    }

    /// Shows a message alert controller to the user.
    /// - Paramter title: The title of the alert controller.
    /// - Parameter message: The message in the alert controller.
    func showMessageAlert(title: String, message: String?, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: completion)
        alertController.view.tintColor = self.view.tintColor
    }

}
