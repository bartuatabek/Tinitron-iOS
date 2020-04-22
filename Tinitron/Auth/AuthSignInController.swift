//
//  AuthSignInController.swift
//  Neverwhere
//
//  Created by Bartu Atabek on 8/30/19.
//  Copyright © 2019 Neverwhere. All rights reserved.
//

import UIKit
import LGButton
import ReactiveSwift
import ReactiveCocoa
import IQKeyboardManagerSwift
import AuthenticationServices

class AuthSignInController: UIViewController {

    var viewModel: AuthViewModeling?
    var isValidEmail = false, isValidPassword = false, email = ""
    var returnKeyHandler: IQKeyboardReturnKeyHandler?

    @IBOutlet weak var inputTextField: FormTextField!
    @IBOutlet weak var credentialTextField: FormTextField!
    @IBOutlet weak var loginButton: LGButton!

    @IBOutlet weak var inputErrorLabel: UILabel!
    @IBOutlet weak var passwordErrorLabel: UILabel!

    @IBOutlet weak var activityIndicatorContainer: UIView!
    @IBOutlet weak var signInWithAppleContainer: UIView!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel?.controller = self
        self.viewModel?.resetErrorMessages()
        bindUIElements()
        setupViews()
    }

    override func viewWillLayoutSubviews() {
        setupSignInWIthApple()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupSignInWIthApple()
    }

    // MARK: - ViewController Functions
    fileprivate func setupViews() {
        if isValidEmail && isValidPassword {
            loginButton.isEnabled = true
            loginButton.alpha = 1.0
        } else {
            loginButton.isEnabled = false
            loginButton.alpha = 0.75
        }
    }

    fileprivate func setupSignInWIthApple() {
        let userInterfaceStyle = traitCollection.userInterfaceStyle
        var authorizationButton: ASAuthorizationAppleIDButton

        if userInterfaceStyle == .light {
            authorizationButton = ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: .black)
        } else if userInterfaceStyle == .dark {
            authorizationButton = ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: .white)
        } else {
            authorizationButton = ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: .whiteOutline)
        }

        authorizationButton.cornerRadius = 25
        authorizationButton.contentMode = .scaleAspectFit
        authorizationButton.frame = signInWithAppleContainer.bounds
        authorizationButton.addTarget(self, action: #selector(handleAppleLogin), for: .touchUpInside)
        // Replace the previous button with new styled one
        signInWithAppleContainer.subviews.forEach({ $0.removeFromSuperview() })
        signInWithAppleContainer.addSubview(authorizationButton)
    }

    fileprivate func bindUIElements() {
        inputErrorLabel.reactive.text <~ viewModel!.topErrorLabelMessage
        passwordErrorLabel.reactive.text <~ viewModel!.middleErrorLabelMessage
        returnKeyHandler = IQKeyboardReturnKeyHandler(controller: self)
        returnKeyHandler?.lastTextFieldReturnKeyType = .done
        returnKeyHandler?.delegate = self
        credentialTextField.delegate = self
        if !email.isEmpty { inputTextField.text = email }
    }

    // MARK: TextField Actions
    @IBAction func inputTextDidChange(_ sender: FormTextField) {
        inputTextField.text = inputTextField.text?.trimmingCharacters(in: .whitespaces)

        if let input = inputTextField.text, input.count > 0 {
            if input.contains("@") {
                isValidEmail = (viewModel?.isValidEmail(email: sender.text))!
            } else {
                isValidEmail = true
                viewModel?.resetErrorMessage(errorMessage: .top)
            }
        } else if inputTextField.text!.isEmpty {
            viewModel?.resetErrorMessage(errorMessage: .top)
        }

        setupViews()
    }

    @IBAction func passwordTextDidChange(_ sender: FormTextField) {
        credentialTextField.text = credentialTextField.text?.trimmingCharacters(in: .whitespaces)
        isValidPassword = (viewModel?.isValidPassword(password: credentialTextField.text))!

        if credentialTextField.text!.isEmpty {
            self.viewModel?.resetErrorMessage(errorMessage: .middle)
        }

        setupViews()
    }

    // MARK: - Button Actions
    @objc func handleAppleLogin() {
        activityIndicatorContainer.isHidden = false
        let request = viewModel?.startSignInWithAppleFlow()
        let authorizationController = ASAuthorizationController(authorizationRequests: [request!])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    @IBAction func handleLogin(_ sender: Any) {
        inputTextField.resignFirstResponder()
        credentialTextField.resignFirstResponder()
        activityIndicatorContainer.isHidden = false
        loginButton.isLoading = true

        viewModel?.mailLogin(email: inputTextField.text!, password: credentialTextField.text!, completion: { (finished, result) in
            if finished && result {
                self.viewModel?.segueToHome()
            } else {
                self.activityIndicatorContainer.isHidden = true
                self.loginButton.isLoading = false
            }
        })
    }

    @IBAction func goToSignUp(_ sender: Any) {
        if !(navigationController?.popToViewController(ofClass: AuthSignUpController.self))! {
            let mainStoryboard = UIStoryboard(name: "Auth", bundle: nil)
            if let viewController = mainStoryboard.instantiateViewController(withIdentifier: "SignUp") as? AuthSignUpController {
                viewController.viewModel = self.viewModel
                navigationController?.pushViewController(viewController, animated: true)
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToResetPassword" {
            let authResetController = segue.destination as? AuthResetController
            authResetController?.viewModel = viewModel
        }
    }
}

// MARK: - UITextFieldDelegate & UITextViewDelegate
extension AuthSignInController: UITextFieldDelegate, UITextViewDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == credentialTextField {
            if isValidEmail && isValidPassword {
                handleLogin(textField)
            } else {
                credentialTextField.resignFirstResponder()
                inputTextField.becomeFirstResponder()
            }
        }
        return true
    }
}

@available(iOS 13.0, *)
extension AuthSignInController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {

        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = viewModel?.currentNonce.value else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }

            viewModel?.signInWithApple(idTokenString: idTokenString, nonce: nonce, completion: { (finished, result) in
                if finished && result {
                    self.viewModel?.segueToHome()
                } else {
                    self.activityIndicatorContainer.isHidden = true
                }
            })
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print("Sign in with Apple errored: \(error)")
        self.activityIndicatorContainer.isHidden = true
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
}
