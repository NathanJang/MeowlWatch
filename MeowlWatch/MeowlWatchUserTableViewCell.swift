//
//  MeowlWatchUserTableViewCell.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-05-01.
//  Copyright © 2018 Jonathan Chan. All rights reserved.
//

import UIKit

/// A cell that contains the user's name and meal plan.
class MeowlWatchUserTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var planLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
