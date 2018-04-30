//
//  DiningLocationTableViewCell.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-05-01.
//  Copyright © 2018 Jonathan Chan. All rights reserved.
//

import UIKit

class MeowlWatchDiningLocationTableViewCell: UITableViewCell {

    @IBOutlet weak var locationNameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
