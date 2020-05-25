//
//  AccountController.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/11/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import UIKit
import Firebase
import Kingfisher

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
        setupViews()
    }

    fileprivate func setupViews() {
        let url = Auth.auth().currentUser?.photoURL
        let processor = DownsamplingImageProcessor(size: profilePicture.frame.size)
        profilePicture.kf.setImage(
            with: url,
            placeholder: viewModel?.profilePicture,
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(1)),
                .cacheOriginalImage
        ]) { result in
            switch result {
            case .success(let value):
                self.viewModel?.profilePicture = value.image
            case .failure(let error):
                print("Job failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Button actions
    @IBAction func signOut(_ sender: Any) {
        viewModel?.signOut(completion: { (success) in
            if success {
                #if targetEnvironment(macCatalyst)
                self.performSegue(withIdentifier: "goToSignOutMac", sender: self)
                #else
                self.performSegue(withIdentifier: "goToSignOut", sender: self)
                #endif
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
