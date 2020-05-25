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
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                writeReview()
            } else if indexPath.row == 1 {
                share()
            }
        }
        if indexPath.section == 1 {
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
            } else if indexPath.row == 2 {
                if let url = URL(string: "https://raw.githubusercontent.com/bartuatabek/Tinitron-iOS/master/LICENSE") {
                    let config = SFSafariViewController.Configuration()
                    config.entersReaderIfAvailable = true

                    let safariController = SFSafariViewController(url: url, configuration: config)
                    safariController.modalPresentationStyle = .formSheet
                    present(safariController, animated: true)
                }
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    private let productURL = URL(string: "https://apps.apple.com/us/app/tinitron/id1509489379")!

    private func writeReview() {
        var components = URLComponents(url: productURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "action", value: "write-review")
        ]

        guard let writeReviewURL = components?.url else {
            return
        }

        UIApplication.shared.open(writeReviewURL)
    }

    private func share() {
        let activityViewController = UIActivityViewController(activityItems: [productURL],
                                                              applicationActivities: nil)

        present(activityViewController, animated: true, completion: nil)
    }

    private func sendEmail() {
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

    internal func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
