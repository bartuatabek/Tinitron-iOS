//
//  AccountController.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/11/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import UIKit

// swiftlint:disable force_cast
class AccountController: UITableViewController {

    var viewModel: UserAccountViewModeling?

    @IBOutlet weak var profilePicture: RoundImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel = ProfileViewModel()
        self.viewModel?.controller = self
    }

    override func viewWillAppear(_ animated: Bool) {
        bindUIElements()
    }

    // MARK: - ViewController Functions
    fileprivate func bindUIElements() {
        profilePicture.image = viewModel?.profilePicture
    }

    // MARK: - Button actions
    @IBAction func signOut(_ sender: Any) {
        viewModel?.signOut(completion: { (success) in
            if success {
                self.performSegue(withIdentifier: "goToSignOut", sender: self)
            }
        })
    }
}

// MARK: TableViewDelegate
extension AccountController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let detailViewController = self.storyboard?.instantiateViewController(withIdentifier: "AccountDetailsNavigationController") as! UINavigationController
            let accountDetailsController = detailViewController.viewControllers.first as! AccountDetailsController
            accountDetailsController.viewModel = viewModel
            self.splitViewController?.showDetailViewController(detailViewController, sender: self)
        } else if indexPath.row == 1 {
            let detailViewController = self.storyboard?.instantiateViewController(withIdentifier: "SettingsNavigationController") as! UINavigationController
            self.splitViewController?.showDetailViewController(detailViewController, sender: self)
        } else if indexPath.row == 2 {
            let detailViewController = self.storyboard?.instantiateViewController(withIdentifier: "AboutNavigationController") as! UINavigationController
            self.splitViewController?.showDetailViewController(detailViewController, sender: self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
