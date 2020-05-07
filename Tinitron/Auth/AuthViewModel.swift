//
//  AuthViewModel.swift
//  Neverwhere
//
//  Created by Bartu Atabek on 8/31/19.
//  Copyright © 2019 Bartu Atabek. All rights reserved.
//

import Firebase
import Alamofire
import CryptoKit
import MessageUI
import Foundation
import ReactiveSwift
import ReactiveCocoa
import AuthenticationServices

enum ErrorMessage {
    case top, middle, bottom
}

protocol AccountViewModeling {
    var controller: UIViewController? { get set }

    func isValidPassword(password: String?) -> Bool
    func isSecurePassword(password: String?) -> Bool
    func isPasswordsMatching(password: String?, verify: String?) -> Bool

    func sendPasswordResetMail(email: String, completion: @escaping (Bool, Bool) -> Void)
}

protocol AuthViewModeling: AccountViewModeling {
    var topErrorLabelMessage: MutableProperty<String> { get }
    var middleErrorLabelMessage: MutableProperty<String> { get }
    var bottomErrorLabelMessage: MutableProperty<String> { get }

    var currentNonce: MutableProperty<String> { get }

    func segueToHome()
    func resetErrorMessages()
    func resetErrorMessage(errorMessage: ErrorMessage)

    func startSignInWithAppleFlow() -> ASAuthorizationAppleIDRequest
    func signInWithApple(idTokenString: String, nonce: String, completion: @escaping (Bool, Bool) -> Void)

    func isValidEmail(email: String?) -> Bool
    func mailLogin(email: String, password: String, completion: @escaping (Bool, Bool) -> Void)
    func mailRegister(email: String, password: String, completion: @escaping (Bool, Bool) -> Void)

    func signOut()
}

class AuthViewModel: AuthViewModeling {

    // MARK: - Properties
    weak var controller: UIViewController?

    let topErrorLabelMessage: MutableProperty<String>
    let middleErrorLabelMessage: MutableProperty<String>
    let bottomErrorLabelMessage: MutableProperty<String>

    internal let currentNonce: MutableProperty<String>

    // MARK: - Initialization
    init() {
        self.topErrorLabelMessage = MutableProperty("")
        self.middleErrorLabelMessage = MutableProperty("")
        self.bottomErrorLabelMessage = MutableProperty("")
        self.currentNonce = MutableProperty("")
    }

    func segueToHome() {
        let defaults = UserDefaults.standard
        defaults.set("false", forKey: Auth.auth().currentUser!.uid)

        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let homeController = storyboard.instantiateViewController(identifier: "HomeTabBarController") as UITabBarController
         homeController.modalPresentationStyle = .fullScreen
        self.controller?.present(homeController, animated: true, completion: nil)

        let currentUser = Auth.auth().currentUser
        currentUser?.getIDTokenForcingRefresh(true) { idToken, error in
            if let error = error {
                print("Cannot get token: ", error )
                return
            }

            print(idToken ?? "")
        }
    }

    func resetErrorMessages() {
        topErrorLabelMessage.swap("")
        middleErrorLabelMessage.swap("")
        bottomErrorLabelMessage.swap("")
    }

    func resetErrorMessage(errorMessage: ErrorMessage) {
        switch errorMessage {
        case .top:
            topErrorLabelMessage.swap("")
        case .middle:
            middleErrorLabelMessage.swap("")
        case .bottom:
            bottomErrorLabelMessage.swap("")
        }
    }

    // MARK: - Sign in with Apple Authentication
    @available(iOS 13, *)
    func startSignInWithAppleFlow() -> ASAuthorizationAppleIDRequest {
        let nonce = randomNonceString()
        currentNonce.swap(nonce)
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        return request
    }

    func signInWithApple(idTokenString: String, nonce: String, completion: @escaping (Bool, Bool) -> Void) {
        // Initialize a Firebase credential.
        let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)

        // Sign in with Firebase.
        print("New user signed up.")
        Auth.auth().signIn(with: credential) { (_, error) in
            if let error = error {
                // Error. If error.code == .MissingOrInvalidNonce, make sure
                // you're sending the SHA256-hashed nonce as a hex string with
                // your request to Apple.
                print(error.localizedDescription)
                self.controller?.showAlert(withTitle: "Login Failed", message: error.localizedDescription, option1: "OK", option2: nil)
                completion(true, false)
                return
            }
            // User is signed in to Firebase with Apple.

            let currentUser = Auth.auth().currentUser
            currentUser?.getIDTokenForcingRefresh(true) { idToken, error in
                if let error = error {
                    print("Cannot get token: ", error )
                    return
                }

                self.createUser(idToken: idToken, uid: currentUser!.uid, username: currentUser?.displayName, email: (currentUser?.email)!, password: "tinitronic")
            }
            completion(true, true)
        }
    }

    // MARK: - Verification
    func isValidEmail(email: String?) -> Bool {
        guard email != nil else { return false }
        let regEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let pred = NSPredicate(format: "SELF MATCHES %@", regEx)
        if pred.evaluate(with: email) {
            topErrorLabelMessage.swap("")
            return true
        } else {
            topErrorLabelMessage.swap("This email is invalid. Make sure it's written in the form example@email.com")
            return false
        }
    }

    func isValidPassword(password: String?) -> Bool {
        if password!.count > 7 {
            middleErrorLabelMessage.swap("")
            return true
        } else {
            middleErrorLabelMessage.swap("Use at least 8 characters.")
            return false
        }
    }

    func isSecurePassword(password: String?) -> Bool {
        guard let password = password else { return false }
        let regex = "(?:(?:(?=.*?[0-9])(?=.*?[-!@#$%&*ˆ+=_])|(?:(?=.*?[0-9])|(?=.*?[A-Z])|(?=.*?[-!@#$%&*ˆ+=_])))|(?=.*?[a-z])(?=.*?[0-9])(?=.*?[-!@#$%&*ˆ+=_]))[A-Za-z0-9-!@#$%&*ˆ+=_]{8,}"
        if NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: password) {
            middleErrorLabelMessage.swap("")
            return true
        } else {
            middleErrorLabelMessage.swap("This password is too weak. Try including a number, symbol, or uppercase letter.")
            return false
        }
    }

    func isPasswordsMatching(password: String?, verify: String?) -> Bool {
        if isValidPassword(password: password) && password == verify {
            bottomErrorLabelMessage.swap("")
            return true
        } else {
            bottomErrorLabelMessage.swap("Passwords do not match.")
            return false
        }
    }

    // MARK: - Mail Authentication
    func mailLogin(email: String, password: String, completion: @escaping (Bool, Bool) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { user, error in
            if let error = error {
                print("Login failed: ", error)
                self.controller?.showAlert(withTitle: "Login Failed", message: error.localizedDescription, option1: "Try Again", option2: "Send Email")
                self.signOut()
                completion(true, false)
            } else {
                if let user = user?.user {
                    completion(true, true)
                    print("uid: " + user.uid)
                    print("email: " + (user.email ?? ""))
                    print("photoURL: \(String(describing: user.photoURL))")
                    return
                }
                self.signOut()
                completion(true, false)
                self.controller?.showAlert(withTitle: "Login Failed", message: "Something went wrong, please try again later.", option1: "OK", option2: nil)
            }
        }
    }

    // swiftlint:disable force_cast
    func mailRegister(email: String, password: String, completion: @escaping (Bool, Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            if let error = error {
                print("Registration failed: ", error)
                let alert = UIAlertController(title: "Registration Failed", message: error.localizedDescription, preferredStyle: .alert)

                alert.addAction(UIAlertAction(title: "Contact Support", style: .default, handler: { _ in
                    if MFMailComposeViewController.canSendMail() {
                        let mail = MFMailComposeViewController()
                        mail.mailComposeDelegate = self.controller as! AuthSignUpController
                        mail.setToRecipients(["support@neverwhere.app"])
                        mail.setSubject("[\(UUID().uuidString)]: Account Creation Failure")
                        mail.setMessageBody("An issue in the app is making me crazy, help!", isHTML: false)
                        self.controller!.present(mail, animated: true)
                    } else {
                        self.controller?.showAlert(withTitle: "Operation Failed", message: "Something went wrong, please try again later.", option1: "OK", option2: nil)
                    }
                }))

                alert.addAction(UIAlertAction(title: "Try Again", style: .cancel, handler: nil))
                self.controller!.present(alert, animated: true)
                self.signOut()
                completion(true, false)
            } else {
                print("Register Successful")

                let currentUser = Auth.auth().currentUser
                currentUser?.getIDTokenForcingRefresh(true) { idToken, error in
                    if let error = error {
                        print("Cannot get token: ", error )
                        return
                    }

                    self.createUser(idToken: idToken, uid: currentUser!.uid, username: currentUser?.displayName, email: email, password: password)
                }

                if let user = authResult?.user {
                    print("uid: " + user.uid)
                    print("email: " + (user.email ?? ""))
                    print("photoURL: \(String(describing: user.photoURL))")
                }
                completion(true, true)
            }
        }
    }

    // MARK: - Password Reset Operations
    func sendPasswordResetMail(email: String, completion: @escaping (Bool, Bool) -> Void) {
        if isValidEmail(email: email) {
            Auth.auth().useAppLanguage()
            Auth.auth().sendPasswordReset(withEmail: email) { (error) in
                if let error = error {
                    self.controller?.showAlert(withTitle: "Operation Failed", message: error.localizedDescription, option1: "OK", option2: nil)
                    print("Cannot send password reset mail: ", error )
                    completion(true, false)
                    return
                }
                completion(true, true)
                return
            }
        } else {
            completion(true, false)
        }
    }

    // MARK: - Profile Operations
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
            self.controller?.showAlert(withTitle: "Unable to Sign Out", message: signOutError.localizedDescription, option1: "OK", option2: nil)
        }
    }

    // MARK: - Encryption Funtions
    // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    private func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      let charset: [Character] =
          Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
      var result = ""
      var remainingLength = length

      while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
          var random: UInt8 = 0
          let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
          if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
          }
          return random
        }

        randoms.forEach { random in
          if length == 0 {
            return
          }

          if random < charset.count {
            result.append(charset[Int(random)])
            remainingLength -= 1
          }
        }
      }

      return result
    }

    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        return String(format: "%02x", $0)
      }.joined()

      return hashString
    }

    // MARK: - Microservice User Creation
    private func createUser(idToken: String?, uid: String, username: String?, email: String, password: String) {
        let parameters: Parameters = [
            "id": uid,
            "username": username ?? NSNull(),
            "email": email,
            "password": password
        ]

        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(idToken ?? "")"
        ]

        AF.request("http://34.66.247.212:8080/users/create", method: .post, parameters: parameters, headers: headers)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                debugPrint(response)
                switch response.result {
                case .success:
                    return
                case .failure(let error):
                    print(error)
                }
        }
    }
}
