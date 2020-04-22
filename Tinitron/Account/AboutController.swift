//
//  AboutController.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/22/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import UIKit
import Firebase
import MessageUI
import SafariServices

class AboutController: UITableViewController, MFMailComposeViewControllerDelegate {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            sendEmail()
        } else if indexPath.row == 1 {
            if let url = URL(string: "https://neverwhere.app/legal/privacy") {
                let config = SFSafariViewController.Configuration()
                config.entersReaderIfAvailable = true

                let safariController = SFSafariViewController(url: url, configuration: config)
                safariController.modalPresentationStyle = .formSheet
                present(safariController, animated: true)
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 4
        } else { return 0 }
    }

    func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["support@tinitron.ml"])
            mail.setSubject("Support Request for User \(Auth.auth().currentUser?.uid ?? "nil")")

            present(mail, animated: true)
        } else {
            // show failure alert
        }
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
