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
        configureView()
    }

    func configureView() {
//        buttonView.setBackgroundColor(highlightedBackgroundColor, for: .highlighted)
//        buttonView.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
//        let gestureRecognizer = UIGestureRecognizer()
//        self.addGestureRecognizer(gestureRecognizer)
    }

    func didTap() {
        sectionHidden = !sectionHidden
        updateView(animated: true)
        if sectionHidden {
            delegate?.sectionHeaderView(self, sectionClosed: section)
        } else {
            delegate?.sectionHeaderView(self, sectionOpened: section)
        }
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var disclosureIndicatorView: UIImageView!
    @IBOutlet weak var bottomBorderView: UIView!
    
    var delegate: SectionHeaderViewDelegate?

    private var disclosureIndicatorIsRotated = false

    /// Updates disclosure view orientation, and color.
    func updateView(animated: Bool) {
        if disclosureIndicatorIsRotated && !sectionHidden || !disclosureIndicatorIsRotated && sectionHidden {
            return
        }
        let angleInRadians: CGFloat = sectionHidden ? -90 * .pi / 180 : 90 * .pi / 180
        self.layer.backgroundColor = self.highlightedBackgroundColor.cgColor
        UIView.animate(withDuration: animated ? 0.25 : 0, animations: {
            self.disclosureIndicatorView.transform = self.disclosureIndicatorView.transform.rotated(by: angleInRadians)
            self.bottomBorderView.alpha = self.sectionHidden ? 1 : 0
            self.layer.backgroundColor = UIColor.clear.cgColor
        })
        disclosureIndicatorIsRotated = !sectionHidden
    }

    var sectionHidden = false

    var section: Int = -1

    var highlighted = false

    fileprivate let highlightedBackgroundColor: UIColor = UIColor(red: 0xD0/0xFF, green: 0xD0/0xFF, blue: 0xD0/0xFF, alpha: 1)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        highlighted = true
        self.layer.backgroundColor = highlightedBackgroundColor.cgColor
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if highlighted {
            didTap()
            updateView(animated: true)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        self.layer.backgroundColor = UIColor.clear.cgColor
    }

}

protocol SectionHeaderViewDelegate: class {

    func sectionHeaderView(_ sectionHeaderView: MeowlWatchSectionHeaderView, sectionOpened section: Int)
    func sectionHeaderView(_ sectionHeaderView: MeowlWatchSectionHeaderView, sectionClosed section: Int)
    var hiddenSections: [Int] { get set }

}

extension UIButton {

    fileprivate func setBackgroundColor(_ color: UIColor, for state: UIControlState) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        guard let currentContext = UIGraphicsGetCurrentContext() else { return }
        currentContext.setFillColor(color.cgColor)
        currentContext.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.setBackgroundImage(colorImage, for: state)
    }

}
