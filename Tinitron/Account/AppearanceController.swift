//
//  AppearanceController.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/21/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import UIKit

class AppearanceController: UITableViewController {

    let defaults = UserDefaults.standard

    override func viewDidLayoutSubviews() {
        for cell in tableView.visibleCells {
            cell.accessoryType = .none
        }

        let index = defaults.integer(forKey: "appearance")
        let indexPath = IndexPath(row: index, section: 0)
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        for cell in tableView.visibleCells {
            cell.accessoryType = .none
        }

        if indexPath.row == 0 {
            UIApplication.shared.windows.forEach { window in
                window.overrideUserInterfaceStyle = .unspecified
            }
        } else if indexPath.row == 1 {
            UIApplication.shared.windows.forEach { window in
                window.overrideUserInterfaceStyle = .light
            }
        } else if indexPath.row == 2 {
            UIApplication.shared.windows.forEach { window in
                window.overrideUserInterfaceStyle = .dark
            }
        }

        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
        }

        defaults.set(indexPath.row, forKey: "appearance")
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
