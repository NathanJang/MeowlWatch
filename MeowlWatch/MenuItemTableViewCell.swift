//
//  MenuItemTableViewCell.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2019-09-21.
//  Copyright © 2019 Jonathan Chan. All rights reserved.
//

import UIKit

class MenuItemTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var additionalMargin: NSLayoutConstraint!

    var subtitleLabelText: String? {
        get { return subtitleLabel.text }
        set {
            subtitleLabel.text = newValue
            guard let text = newValue, !text.isEmpty else {
                additionalMargin.constant = 0
                return
            }
            additionalMargin.constant = 4
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
