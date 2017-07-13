//
//  iOS11Shim.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-07-13.
//  Copyright © 2017 Jonathan Chan. All rights reserved.
//

import UIKit

@available(iOS, deprecated: 11.0)
extension UINavigationBar {
    var prefersLargeTitles: Bool {
        get { return false }
        set {}
    }
}

@available(iOS, deprecated: 11.0)
extension UINavigationItem {
    enum LargeTitleDisplayMode {
        case automatic
        case always
        case never
    }
    var largeTitleDisplayMode: LargeTitleDisplayMode {
        get { return .automatic }
        set {}
    }
    var searchController: UISearchController? {
        get { return nil }
        set {}
    }
    var hidesSearchBarWhenScrolling: Bool {
        get { return true }
        set {}
    }
}

@available(iOS, deprecated: 11.0)
extension UITableView {
    var adjustedContentInset: UIEdgeInsets {
        get { return contentInset }
        set {}
    }
}
