//
//  CreateLinkController.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/13/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift

class CreateLinkController: UITableViewController {

    var noOfSections = 2
    var expireDate: Date?
    var isValidURL = false, isValidCustomURL = true, customized = false
    var viewModel: LinksViewModeling?

    var returnKeyHandler: IQKeyboardReturnKeyHandler?
    let dateFormatter = DateFormatter()

    @IBOutlet weak var longURLTextField: FormTextField!

    @IBOutlet weak var customAddressTextField: FormTextField!
    @IBOutlet weak var passwordTextField: FormTextField!
    @IBOutlet weak var expirationDateTextField: FormTextField!

    @IBOutlet weak var saveButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel?.controller = self
        updateButtonStatus()

        dateFormatter.dateFormat = "MM/dd/yyyy"
        expireDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        expirationDateTextField.text = dateFormatter.string(from: expireDate!)
        returnKeyHandler = IQKeyboardReturnKeyHandler(controller: self)

        let datePickerView = UIDatePicker()
        datePickerView.datePickerMode = .date
        datePickerView.date = expireDate!
        datePickerView.minimumDate = Date()
        datePickerView.maximumDate = expireDate
        datePickerView.addTarget(self, action: #selector(handleDatePicker(sender:)), for: .valueChanged)
        expirationDateTextField.inputView = datePickerView
        expirationDateTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(doneButtonClicked))
        self.tableView.deleteSections(IndexSet(integer: 2), with: .none)
    }

    // MARK: - ViewController Functions
    fileprivate func updateButtonStatus() {
        if isValidURL && isValidCustomURL {
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
        }
    }

    @IBAction func showAdvancedOptions(_ sender: UISwitch) {
        if sender.isOn {
            noOfSections = 3
            customized = true
            self.tableView.insertSections(IndexSet(integer: 2), with: .fade)
        } else {
            noOfSections = 2
            customized = false
            self.tableView.deleteSections(IndexSet(integer: 2), with: .fade)
        }
    }

    // MARK: TextField Actions
    @IBAction func linkTextFieldChanged(_ sender: Any) {
        if  longURLTextField.text!.isEmpty {
            isValidURL = false
            longURLTextField.tintColor = .systemBlue
            longURLTextField.rightImage = nil
        } else if longURLTextField.text!.isValidURL {
            isValidURL = true
            longURLTextField.tintColor = .systemBlue
            longURLTextField.rightImage = UIImage(systemName: "checkmark.circle")
        } else {
            isValidURL = false
            longURLTextField.tintColor = .systemRed
            longURLTextField.rightImage = UIImage(systemName: "exclamationmark.circle")
        }
        updateButtonStatus()
    }

    @IBAction func shortLinkTextFieldChanged(_ sender: Any) {
        if customAddressTextField.text!.isEmpty {
            isValidCustomURL = true
            customAddressTextField.tintColor = .systemBlue
            customAddressTextField.rightImage = nil
        } else if customAddressTextField.text!.isAlphanumeric {
            isValidCustomURL = true
            customAddressTextField.tintColor = .systemBlue
            customAddressTextField.rightImage = UIImage(systemName: "checkmark.circle")
        } else {
            isValidCustomURL = false
            customAddressTextField.tintColor = .systemRed
            customAddressTextField.rightImage = UIImage(systemName: "exclamationmark.circle")
        }
        updateButtonStatus()
    }

    @IBAction func expirationDateTextFieldEditingBegin(_ sender: Any) {
        IQKeyboardManager.shared.enableAutoToolbar = true
    }

    @IBAction func expirationDateTextFieldEditingEnd(_ sender: Any) {
        IQKeyboardManager.shared.enableAutoToolbar = false
    }

    // MARK: - Button Actions
    @IBAction func saveLink(_ sender: Any) {
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        let barButton = UIBarButtonItem(customView: activityIndicator)
        self.navigationItem.setRightBarButton(barButton, animated: true)
        activityIndicator.startAnimating()

        let shortURL = customAddressTextField.text!.isEmpty ? "" : customAddressTextField.text
        let newLink = Link(title: longURLTextField.text!, originalURL: longURLTextField.text!, shortURL: shortURL!, expirationDate: expireDate!, password: passwordTextField.text!)

        viewModel?.createNewLink(for: newLink, completion: { (finished, success, newLink) in
            if finished && success {
                self.viewModel?.links.append(newLink!)

                let homeController = self.presentingViewController as? UITabBarController
                let splitViewController = homeController?.selectedViewController as? UISplitViewController
                let navigationController = splitViewController?.masterViewController as? UINavigationController
                let linksContoller = navigationController?.topViewController as? LinksController
                linksContoller!.refresh(linksContoller!.refreshControl!)

                self.dismiss(animated: true, completion: nil)
            } else if finished && !success {
                self.navigationItem.setRightBarButton(UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(self.saveLink(_:))), animated: true)
            }
        })
    }

    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return noOfSections
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 && indexPath.row == 2 {
            expirationDateTextField.becomeFirstResponder()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    @objc func handleDatePicker(sender: UIDatePicker) {
        expirationDateTextField.text = dateFormatter.string(from: sender.date)
    }

    @objc func doneButtonClicked(_ sender: Any) {
        expirationDateTextField.resignFirstResponder()
    }
}

// MARK: - UITableViewDataSource
extension CreateLinkController {
    override func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        if (indexPath.section == 2 && indexPath.row == 1) || (indexPath.section == 1) {
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
}
