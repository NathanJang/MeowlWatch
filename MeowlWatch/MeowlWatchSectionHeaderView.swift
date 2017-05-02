//
//  MeowlWatchSectionHeaderView.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-05-02.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import UIKit

class MeowlWatchSectionHeaderView: UITableViewHeaderFooterView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    override func awakeFromNib() {
        super.awakeFromNib()
        configureButtonView()
    }

    func configureButtonView() {
        let highlightedBackgroundColor = UIColor(red: 0xD0/0xFF, green: 0xD0/0xFF, blue: 0xD0/0xFF, alpha: 1)
        buttonView.setBackgroundColor(highlightedBackgroundColor, for: .highlighted)
        buttonView.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
    }

    func didTapButton() {
        sectionHidden = !sectionHidden
        updateDisclosureIndicatorOrientation(animated: true)
        if sectionHidden {
            delegate?.sectionHeaderView(self, sectionClosed: section)
        } else {
            if let delegate = delegate {
                delegate.sectionHeaderView(self, sectionOpened: section)
            }
        }
    }

    @IBOutlet weak var buttonView: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var disclosureIndicatorView: UIImageView!

    var delegate: SectionHeaderViewDelegate?

    private var disclosureIndicatorIsRotated = false

    func updateDisclosureIndicatorOrientation(animated: Bool) {
        if disclosureIndicatorIsRotated && !sectionHidden || !disclosureIndicatorIsRotated && sectionHidden {
            return
        }
        let angleInRadians: CGFloat = sectionHidden ? -90 * .pi / 180 : 90 * .pi / 180
        UIView.animate(withDuration: animated ? 0.25 : 0) {
            self.disclosureIndicatorView.transform = self.disclosureIndicatorView.transform.rotated(by: angleInRadians)
        }
        disclosureIndicatorIsRotated = !sectionHidden
    }

    var sectionHidden = false

    var section: Int = -1

}

protocol SectionHeaderViewDelegate: class {

    func sectionHeaderView(_ sectionHeaderView: MeowlWatchSectionHeaderView, sectionOpened section: Int)
    func sectionHeaderView(_ sectionHeaderView: MeowlWatchSectionHeaderView, sectionClosed section: Int)
    var hiddenSections: [Int] { get set }

}

extension UIButton {

    func setBackgroundColor(_ color: UIColor, for state: UIControlState) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.setBackgroundImage(colorImage, for: state)
    }

}
