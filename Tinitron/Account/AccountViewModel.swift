//
//  AccountViewModel.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/10/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import Firebase
import Alamofire
import FirebaseStorage

protocol UserAccountViewModeling: AccountViewModeling {

    var email: String { get set }
    var username: String { get set }
    var currentPassword: String { get set }
    var newPassword: String { get set }
    var confirmPassword: String { get set }
    var profilePicture: UIImage { get set }

    func saveChanges(completion: @escaping (Bool) -> Void)
    func changeProfilePicture(with photo: UIImage)
    func changeUsername(name: String, completion: @escaping (Bool) -> Void)
    func changePassword(currentPassword: String, newPassword: String, confirmPassword: String, completion: @escaping (Bool) -> Void)

    func signOut(completion: @escaping (Bool) -> Void)
    func deleteAccount(password: String, completion: @escaping (Bool) -> Void)
}

class ProfileViewModel: UserAccountViewModeling {

    // MARK: - Properties
    weak var controller: UIViewController?

    var email: String
    var username: String
    var currentPassword: String
    var newPassword: String
    var confirmPassword: String
    var profilePicture: UIImage

    // MARK: - Initialization
    init() {
        self.email = Auth.auth().currentUser?.email ?? ""
        self.username = Auth.auth().currentUser?.displayName ?? ""
        self.currentPassword = ""
        self.newPassword = ""
        self.confirmPassword = ""
        self.profilePicture = loadImageFromDiskWith(fileName: Auth.auth().currentUser!.uid) ?? UIImage(systemName: "person.crop.circle")!
    }

    // MARK: - Error Message Handling
    func resetErrorMessages() {
    }

    // MARK: - Verification
    func isValidEmail(email: String?) -> Bool {
        guard email != nil else { return false }
        let regEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let pred = NSPredicate(format: "SELF MATCHES %@", regEx)
        if pred.evaluate(with: email) {
            return true
        } else {
            self.controller?.showAlert(withTitle: "Operation Failed", message: "This email is invalid. Make sure it's written in the form example@email.com", option1: "OK", option2: nil)
            return false
        }
    }

    func isValidPassword(password: String?) -> Bool {
        if password!.count > 7 {
            return true
        } else {
            self.controller?.showAlert(withTitle: "Operation Failed", message: "Use at least 8 characters.", option1: "OK", option2: nil)
            return false
        }
    }

    func isSecurePassword(password: String?) -> Bool {
        guard let password = password else { return false }
        let regex = "(?:(?:(?=.*?[0-9])(?=.*?[-!@#$%&*ˆ+=_])|(?:(?=.*?[0-9])|(?=.*?[A-Z])|(?=.*?[-!@#$%&*ˆ+=_])))|(?=.*?[a-z])(?=.*?[0-9])(?=.*?[-!@#$%&*ˆ+=_]))[A-Za-z0-9-!@#$%&*ˆ+=_]{8,}"
        if NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: password) {
            return true
        } else {
            self.controller?.showAlert(withTitle: "Operation Failed", message: "This password is too weak. Try including a number, symbol, or uppercase letter.", option1: "OK", option2: nil)
            return false
        }
    }

    func isPasswordsMatching(password: String?, verify: String?) -> Bool {
        if isValidPassword(password: password) && password == verify {
            return true
        } else {
            self.controller?.showAlert(withTitle: "Operation Failed", message: "Passwords do not match.", option1: "OK", option2: nil)
            return false
        }
    }

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

    // MARK: - Update User Profile
    func saveChanges(completion: @escaping (Bool) -> Void) {
        if !username.isEmpty && username != Auth.auth().currentUser?.displayName {
            changeUsername(name: username) { (result) in
                if !result { completion(false); return }
            }
        }

        changeProfilePicture(with: profilePicture)
        changePassword(currentPassword: currentPassword, newPassword: newPassword, confirmPassword: confirmPassword) { (result) in
            if !result { completion(false); return }
        }
        completion(true)
    }

    func changeUsername(name: String, completion: @escaping (Bool) -> Void) {
        let user = Auth.auth().currentUser
        let changeRequest = user?.createProfileChangeRequest()
        changeRequest?.displayName = name
        changeRequest?.commitChanges(completion: { (error) in
            if let error = error {
                print("Profile update failed: ", error)
                self.controller?.showAlert(withTitle: "Operation Failed", message: error.localizedDescription, option1: "OK", option2: nil)
                completion(false)
            } else {
                user?.getIDTokenForcingRefresh(true) { idToken, error in
                    if let error = error {
                        print("Cannot get token: ", error )
                        return
                    }

                    self.updateUser(idToken: idToken, uid: user!.uid, username: user?.displayName, password: nil)
                }

                completion(true)
            }
        })
    }

    func changeProfilePicture(with photo: UIImage) {
        if photo != UIImage(systemName: "person.crop.circle") {
            saveImage(imageName: Auth.auth().currentUser!.uid, image: photo)
        }

        // Upload image to storage and get the image url
        let currentUser = Auth.auth().currentUser
        let uid = currentUser?.uid ?? ""
        let storageRef = Storage.storage().reference().child("/users/\(uid)/profilePicture.jpeg")

        if let uploadData = photo.jpegData(compressionQuality: 1.0) {
            // Create file metadata including the content type
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            storageRef.putData(uploadData, metadata: metadata, completion: { (_, error) in
                if let error = error {
                    print("Image upload failed: ", error)
                    return
                } else {
                    storageRef.downloadURL(completion: { (url, error) in
                        if let error = error {
                            print("URL download failed: ", error)
                        } else {
                            // Update Display Name & photoURL
                            print("Image URL: \((url?.absoluteString)!)")

                            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                            changeRequest?.photoURL = url
                            changeRequest?.commitChanges(completion: { (error) in
                                if let error = error {
                                    print("Profile update failed: ", error)
                                } else {
                                }
                            })
                        }
                    })
                }
            })
        }
    }

    func changePassword(currentPassword: String, newPassword: String, confirmPassword: String, completion: @escaping (Bool) -> Void) {
        if currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty {
            completion(true)
            return
        }

        if isValidPassword(password: newPassword) {
            if isPasswordsMatching(password: newPassword, verify: confirmPassword) {
                let user = Auth.auth().currentUser
                      let credential: AuthCredential = EmailAuthProvider.credential(withEmail: (user?.email)!, password: currentPassword)

                      user?.reauthenticate(with: credential, completion: { (_, error) in
                          if let error = error {
                              // An error happened.
                              print("Error reauthenticating: %@", error)
                              self.controller?.showAlert(withTitle: "Unable to update password", message: "Sorry, an unexpected error occurred. Please try again later.", option1: "OK", option2: nil)
                            completion(false)
                            return
                          } else {
                              // User re-authenticated.
                              Auth.auth().currentUser?.updatePassword(to: newPassword, completion: { (error) in
                                  if let error = error {
                                      // An error happened.
                                      print("Error updating password: %@", error)
                                      self.controller?.showAlert(withTitle: "Unable to update password", message: error.localizedDescription, option1: "OK", option2: nil)
                                    completion(false)
                                    return
                                  } else {
                                    user?.getIDTokenForcingRefresh(true) { idToken, error in
                                        if let error = error {
                                            print("Cannot get token: ", error )
                                            return
                                        }

                                        self.updateUser(idToken: idToken, uid: user!.uid, username: user?.displayName, password: newPassword)
                                    }

                                    completion(true)
                                    return
                                }
                              })
                          }
                      })
            }
        }
        completion(false)
    }

    func signOut(completion: @escaping (Bool) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(true)
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
            self.controller?.showAlert(withTitle: "Unable to Sign Out", message: "Sorry, an unexpected error occurred. Please try again later.", option1: "OK", option2: nil)
            completion(false)
        }
    }

    func deleteAccount(password: String, completion: @escaping (Bool) -> Void) {
        let user = Auth.auth().currentUser
        let credential: AuthCredential = EmailAuthProvider.credential(withEmail: (user?.email)!, password: password)

        user?.reauthenticate(with: credential, completion: { (_, error) in
            if let error = error {
                // An error happened.
                print("Error reauthenticating: %@", error)
                self.controller?.showAlert(withTitle: "Unable to Delete Account", message: "Sorry, an unexpected error occurred. Please try again later.", option1: "OK", option2: nil)
                completion(false)
            } else {
                // User re-authenticated.
                user?.getIDTokenForcingRefresh(true) { idToken, error in
                    if let error = error {
                        print("Cannot get token: ", error )
                        return
                    }

                    self.deleteUser(idToken: idToken, uid: user!.uid)
                }

                user?.delete { error in
                    if let error = error {
                        // An error happened.
                        print("Error signing out: %@", error)
                        self.controller?.showAlert(withTitle: "Unable to Delete Account", message: "Sorry, an unexpected error occurred. Please try again later.", option1: "OK", option2: nil)
                        completion(false)
                    } else {
                        // Account deleted.
                        completion(true)
                    }
                }
            }
        })
    }

    // MARK: - Microservice User Update/Delete
    private func updateUser(idToken: String?, uid: String, username: String?, password: String?) {
        let parameters: Parameters = [
            "id": uid,
            "username": username ?? NSNull(),
            "password": password ?? NSNull()
        ]

        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(idToken ?? "")"
        ]

        AF.request("http://34.66.247.212:8080/users/" + uid, method: .put, parameters: parameters, headers: headers)
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

    private func deleteUser(idToken: String?, uid: String) {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(idToken ?? "")"
        ]

        AF.request("http://34.66.247.212:8080/users/" + uid, method: .delete, headers: headers)
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
