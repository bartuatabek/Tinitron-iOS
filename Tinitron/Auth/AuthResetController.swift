//
//  AuthResetController.swift
//  Neverwhere
//
//  Created by Bartu Atabek on 9/1/19.
//  Copyright © 2019 Neverwhere. All rights reserved.
//

import UIKit
import LGButton
import ReactiveSwift
import ReactiveCocoa
import IQKeyboardManagerSwift
import MaterialComponents.MaterialTextControls_OutlinedTextFields

class AuthResetController: UIViewController {

    var viewModel: AuthViewModeling?
    var isValidEmail = false
    var returnKeyHandler: IQKeyboardReturnKeyHandler?

    @IBOutlet weak var emailTextField: MDCOutlinedTextField!
    @IBOutlet weak var resetPasswordButton: LGButton!

    @IBOutlet weak var emailErrorLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel?.controller = self
        self.viewModel?.resetErrorMessages()
        bindUIElements()
        setupViews()

        if UIDevice.current.userInterfaceIdiom == .phone {
            AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AppUtility.lockOrientation(.all)
    }

    // MARK: - ViewController Functions
    fileprivate func setupViews() {
        #if targetEnvironment(macCatalyst)
        emailTextField.label.text = "Email"
        emailTextField.setOutlineColor(.systemBlue, for: .editing)
        emailTextField.setOutlineColor(.darkGray, for: .normal)
        emailTextField.setFloatingLabelColor(.systemBlue, for: .editing)
        emailTextField.setNormalLabelColor(.darkGray, for: .normal)
        #endif

        if self.restorationIdentifier! == "ResetPassword" {
            if isValidEmail {
                resetPasswordButton.isEnabled = true
                resetPasswordButton.alpha = 1.0
            } else {
                resetPasswordButton.isEnabled = false
                resetPasswordButton.alpha = 0.75
            }
        }
    }

    fileprivate func bindUIElements() {
        if self.restorationIdentifier == "ResetPassword" {
            emailErrorLabel.reactive.text <~ viewModel!.topErrorLabelMessage
        }

        returnKeyHandler = IQKeyboardReturnKeyHandler(controller: self)
    }

    // MARK: TextField Actions
    @IBAction func emailTextDidChange(_ sender: UITextField) {
        emailTextField.text = emailTextField.text?.trimmingCharacters(in: .whitespaces)

        if let input = emailTextField.text, input.count > 0 {
            isValidEmail = (viewModel?.isValidEmail(email: sender.text))!
        } else {
            self.viewModel?.resetErrorMessages()
        }

        setupViews()
    }

    // MARK: - Button Actions
    @IBAction func sendResetEmail(_ sender: Any) {
        resetPasswordButton.isLoading = true
        viewModel?.sendPasswordResetMail(email: emailTextField.text!, completion: { (finished, result) in
            if finished && result {
                self.performSegue(withIdentifier: "goToResetPasswordLinkSent", sender: self)
            } else {
                self.resetPasswordButton.isLoading = false
            }
        })
    }

    @IBAction func openMail(_ sender: Any) {
        let mailURL = URL(string: "message://")!
        if UIApplication.shared.canOpenURL(mailURL) {
            UIApplication.shared.open(mailURL)
        }
    }

    @IBAction func dismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
