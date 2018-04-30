//
//  BannerAdToolbar.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-04-06.
//  Copyright © 2018 Jonathan Chan. All rights reserved.
//

import UIKit

/// Subclass of `UIToolbar` that sets the height to 50 for AdMob banner ads.
class BannerAdToolbar: UIToolbar {

    private let bannerAdHeight: CGFloat = 50

    override func layoutSubviews() {
        super.layoutSubviews()

        self.frame.size.height = bannerAdHeight
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var newSize = super.sizeThatFits(size)

        newSize.height = bannerAdHeight
        return newSize
    }

}
