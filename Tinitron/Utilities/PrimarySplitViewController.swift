//
//  PrimarySplitViewController.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/21/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import Foundation
import UIKit

class PrimarySplitViewController: UISplitViewController, UISplitViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.preferredDisplayMode = .allVisible
    }

    func splitViewController(
             _ splitViewController: UISplitViewController,
             collapseSecondary secondaryViewController: UIViewController,
             onto primaryViewController: UIViewController) -> Bool {
        // Return true to prevent UIKit from applying its default behavior
        return true
    }
}
