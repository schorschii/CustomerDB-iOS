//
//  MainSplitViewController.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit

class MainSplitViewController: UISplitViewController, UISplitViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.preferredDisplayMode = .allVisible
        self.maximumPrimaryColumnWidth = self.view.bounds.size.width
        self.preferredPrimaryColumnWidthFraction = 0.4
    }

    func splitViewController(_ splitViewController: UISplitViewController,
             collapseSecondary secondaryViewController: UIViewController,
             onto primaryViewController: UIViewController) -> Bool {
        return true
    }
    
    func closeDetailViewController() {
        if(!isCollapsed) {
            let detailViewController = storyboard?.instantiateViewController(withIdentifier: "BlankDetailsViewController")
            showDetailViewController(detailViewController!, sender: nil)
        }
    }
    
}
