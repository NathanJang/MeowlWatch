//
//  MeowlWatchTableViewCell.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-04-13.
//  Copyright © 2018 Jonathan Chan. All rights reserved.
//

import UIKit

/// A cell that contains a piece of information in the user's meal plan, like how many meal swipes remaining.
class MeowlWatchTableViewCell: UITableViewCell {
    
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    @IBOutlet weak var numberLabelWidthConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        numberLabelWidthConstraint.constant = (frame.size.width - contentView.frame.width) * 0.3
    }
    
}
