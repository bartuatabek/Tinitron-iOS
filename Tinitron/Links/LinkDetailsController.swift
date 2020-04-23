//
//  LinkDetailsController.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/14/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import UIKit
import LGButton
import SkeletonView
import SafariServices
import IQKeyboardManagerSwift

class LinkDetailsController: UITableViewController {

    var link: Link?
    var key: String?
    var viewModel: LinksViewModeling?

    var returnKeyHandler: IQKeyboardReturnKeyHandler?
    let dateFormatter = DateFormatter()

    @IBOutlet weak var titleTextField: FormTextField!
    @IBOutlet weak var creationDateLabel: UILabel!

    @IBOutlet weak var originalURLLabel: UILabel!
    @IBOutlet weak var shortURLTextField: FormTextField!

    @IBOutlet weak var expirationDateTextField: UITextField!
    @IBOutlet weak var passwordTextField: FormTextField!

    @IBOutlet weak var saveChangesButton: LGButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel?.controller = self

        dateFormatter.dateFormat = "MM/dd/yyyy"
        expirationDateTextField.text = dateFormatter.string(from: link!.expirationDate)
        returnKeyHandler = IQKeyboardReturnKeyHandler(controller: self)

        let datePickerView = UIDatePicker()
        datePickerView.datePickerMode = .date
        datePickerView.date = link!.expirationDate
        datePickerView.minimumDate = Date()
        datePickerView.maximumDate = Calendar.current.date(byAdding: .day, value: 30, to: link!.expirationDate)!
        datePickerView.addTarget(self, action: #selector(handleDatePicker(sender:)), for: .valueChanged)
        expirationDateTextField.inputView = datePickerView
        expirationDateTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(doneButtonClicked))
        refreshUI()
    }

    // MARK: - ViewController Functions
    fileprivate func checkExpiration() {
        if link!.isExpired {
            self.navigationItem.rightBarButtonItems![0].isEnabled = false
            self.navigationItem.rightBarButtonItems![1].isEnabled = false
        }
    }

    fileprivate func refreshUI() {
        titleTextField.text = link?.title
        creationDateLabel.text = dateFormatter.string(from: link!.creationDate)
        originalURLLabel.text = link?.originalURL
        shortURLTextField.text = link?.shortURL

        if link!.isExpired {
            shortURLTextField.textColor = .systemPink

            titleTextField.isEnabled = false
            shortURLTextField.isEnabled = false
            expirationDateTextField.isEnabled = false
            passwordTextField.isEnabled = false
            saveChangesButton.alpha = 0.5
            saveChangesButton.isEnabled = false
        } else {
            shortURLTextField.textColor = .link

            titleTextField.isEnabled = true
            shortURLTextField.isEnabled = true
            expirationDateTextField.isEnabled = true
            passwordTextField.isEnabled = true
            saveChangesButton.alpha = 1
            saveChangesButton.isEnabled = true
        }

        expirationDateTextField.text = dateFormatter.string(from: link!.expirationDate)
        passwordTextField.text = link?.password
        checkExpiration()

        key = link?.shortURL
    }

    // MARK: Refresh Control
    @IBAction func refresh(_ sender: UIRefreshControl) {
        view.showAnimatedSkeleton()

        viewModel?.fetchLink(shortURL: key!, completion: { (finished, success, fetchedLink) in
            if finished && success {
                self.link = fetchedLink
                self.refreshUI()
            }

            if finished {
                sender.endRefreshing()
                self.tableView.reloadData()
                self.view.hideSkeleton(transition: .crossDissolve(0.25))
            }
        })
    }

    // MARK: TextField Actions
    @IBAction func titleTextFieldEditingEnd(_ sender: Any) {
        if titleTextField.text != link?.title {
            link?.title = titleTextField.text ?? ""
        }
    }

    @IBAction func shortLinkTextFieldChanged(_ sender: Any) {
        if shortURLTextField.text!.isAlphanumeric {
            shortURLTextField.tintColor = .systemBlue
            shortURLTextField.rightImage = UIImage(systemName: "checkmark.circle")
        } else {
            shortURLTextField.tintColor = .systemRed
            shortURLTextField.rightImage = UIImage(systemName: "exclamationmark.circle")
        }
        link?.shortURL = shortURLTextField.text!
    }

    @IBAction func passwordTextFieldEditingEnd(_ sender: Any) {
        if passwordTextField.text != link?.password {
            link?.password = passwordTextField.text
        }
    }

    @IBAction func expirationDateTextFieldEditingBegin(_ sender: Any) {
        IQKeyboardManager.shared.enableAutoToolbar = true
    }

    @IBAction func expirationDateTextFieldEditingEnd(_ sender: Any) {
        IQKeyboardManager.shared.enableAutoToolbar = false
    }

    // MARK: - Button Actions
    @IBAction func shareLink(_ sender: Any) {
        if let url = URL(string: "https://" + link!.shortURL) {
            let items: [Any] = [url]
            let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)
            activityController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
            present(activityController, animated: true)
        }
    }

    @IBAction func viewLink(_ sender: Any) {
        if let url = URL(string: "https://" + link!.shortURL) {
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = true

            let safariController = SFSafariViewController(url: url, configuration: config)
            safariController.modalPresentationStyle = .formSheet
            present(safariController, animated: true)
        }
    }

    @IBAction func saveChanges(_ sender: LGButton) {
        sender.isLoading = true
        viewModel?.updateLink(link: link!, completion: { (finished, success) in
            if finished && success {
                if let index = self.viewModel?.links.firstIndex(where: {$0.shortURL == self.key}) {
                    self.viewModel?.links[index] = self.link!
                    self.navigationController!.popToRootViewController(animated: true)
                }
                sender.isLoading = false
            } else if finished && !success {
                sender.isLoading = false
            }
        })
    }

    @IBAction func deleteLink(_ sender: LGButton) {
        sender.isLoading = true
        viewModel?.deleteLinks(links: [link!.shortURL], completion: { (finished, success) in
            if finished && success {
                if let index = self.viewModel?.links.firstIndex(where: {$0.shortURL == self.key}) {
                    self.viewModel?.links.remove(at: index)
                    self.navigationController!.popToRootViewController(animated: true)
                }
                sender.isLoading = false
            } else if finished && !success {
                sender.isLoading = false
            }
        })
    }
}

// MARK: - UITableViewDataSource
extension LinkDetailsController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            titleTextField.becomeFirstResponder()
        } else if indexPath.section == 1 && indexPath.row == 1 {
            shortURLTextField.becomeFirstResponder()
        } else if indexPath.section == 2 && indexPath.row == 0 {
            expirationDateTextField.becomeFirstResponder()
        } else if indexPath.section == 2 && indexPath.row == 1 {
            passwordTextField.becomeFirstResponder()
        } else if indexPath.section == 3 {
            let storyboard = UIStoryboard(name: "Analytics", bundle: nil)
            let linkAnalyticsController = storyboard.instantiateViewController(identifier: "LinkAnalytics") as LinkAnalyticsController
            linkAnalyticsController.viewModel = viewModel
            linkAnalyticsController.analyticsData = viewModel?.analyticsData.first(where: { $0.id == link?.shortURL })
            self.navigationController?.pushViewController(linkAnalyticsController, animated: true)
        } else {
            resignFirstResponder()
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 && link!.isExpired {
            return "Expired links cannot be modifed or accessed. They can only be viewed or deleted."
        } else { return nil }
    }

    override func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        if (indexPath.section == 2 && indexPath.row == 1) || (indexPath.section == 3) {
            return false
        } else {
            return (tableView.cellForRow(at: indexPath)?.detailTextLabel?.text) != nil
        }
    }

    override func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
    }

    override func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        if action == #selector(copy(_:)) {
            let cell = tableView.cellForRow(at: indexPath)
            let pasteboard = UIPasteboard.general
            pasteboard.string = cell?.detailTextLabel?.text
        }
    }

    @objc func handleDatePicker(sender: UIDatePicker) {
        expirationDateTextField.text = dateFormatter.string(from: sender.date)
        link?.expirationDate = sender.date
        checkExpiration()
    }

    @objc func doneButtonClicked(_ sender: Any) {
        expirationDateTextField.resignFirstResponder()
    }
}
