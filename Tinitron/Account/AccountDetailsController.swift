//
//  AccountDetailsController.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/10/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import UIKit
import Photos
import Firebase
import Kingfisher

class AccountDetailsController: UITableViewController {

    var viewModel: UserAccountViewModeling?
    var imagePicker = UIImagePickerController()

    @IBOutlet weak var profilePicture: RoundImageView!
    @IBOutlet weak var usernameTextField: FormTextField!
    @IBOutlet weak var emailLabel: UILabel!

    @IBOutlet weak var currrentPasswordTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel?.controller = self
    }

    override func viewWillAppear(_ animated: Bool) {
        bindUIElements()
        setupViews()
    }

    // MARK: - ViewController Functions
    fileprivate func setupViews() {
        self.isModalInPresentation = true

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

    fileprivate func bindUIElements() {
        profilePicture.image = viewModel?.profilePicture
        usernameTextField.text = viewModel?.username
        emailLabel.text = viewModel?.email
    }

    // MARK: TableView Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            if !usernameTextField.isFirstResponder {
                usernameTextField.becomeFirstResponder()
            }
        } else if indexPath.section == 1 && indexPath.row == 0 {
            if !currrentPasswordTextField.isFirstResponder {
                currrentPasswordTextField.becomeFirstResponder()
            }
        } else if indexPath.section == 1 && indexPath.row == 1 {
            if !newPasswordTextField.isFirstResponder {
                newPasswordTextField.becomeFirstResponder()
            }
        } else if indexPath.section == 1 && indexPath.row == 2 {
            if !confirmPasswordTextField.isFirstResponder {
                confirmPasswordTextField.becomeFirstResponder()
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: TextField Actions
    @IBAction func usernameEditingDidEnd(_ sender: Any) {
        self.viewModel?.username = usernameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @IBAction func currentPasswordEditingDidEnd(_ sender: Any) {
        self.viewModel?.currentPassword = currrentPasswordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @IBAction func newPasswordEditingDidEnd(_ sender: Any) {
        self.viewModel?.newPassword = newPasswordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @IBAction func confirmPasswordEditingDidEnd(_ sender: Any) {
        self.viewModel?.confirmPassword = confirmPasswordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Button actions
    @IBAction func save(_ sender: Any) {
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        let barButton = UIBarButtonItem(customView: activityIndicator)
        self.navigationItem.setRightBarButton(barButton, animated: true)
        activityIndicator.startAnimating()

        viewModel?.saveChanges(completion: { (success) in
            if success {
                self.navigationItem.setRightBarButton(UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(self.save(_:))), animated: true)
                if let masterController = self.splitViewController?.masterViewController as? UINavigationController, let accountController = masterController.viewControllers.first as? AccountController {
                    accountController.profilePicture.image = self.viewModel?.profilePicture
                }
            }
        })
    }

    @IBAction func deleteAccount(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: "This will delete all your links and remove all your data from the app.", preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Delete Account", style: .destructive, handler: { _ in
            let alert = UIAlertController(title: nil, message: "You will need to enter your password to delete your account.", preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.placeholder = "Password"
                textField.isSecureTextEntry = true
            }
            alert.addAction(UIAlertAction(title: "Delete Account", style: .destructive, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0]
                self.viewModel?.deleteAccount(password: (textField?.text)!, completion: { (success) in
                    if success {
                        #if targetEnvironment(macCatalyst)
                        self.performSegue(withIdentifier: "goToAuthMac", sender: self)
                        #else
                        self.performSegue(withIdentifier: "goToAuth", sender: self)
                        #endif
                    }
                })
            }))
            alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }))

        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func changeProfilePicture(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Remove Photo", style: .destructive, handler: { _ in
            self.viewModel?.profilePicture = UIImage(systemName: "person.crop.circle")!
            self.profilePicture.image = UIImage(systemName: "person.crop.circle")
            self.profilePicture.tintColor = UIColor.systemGray
        }))

        alert.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { _ in
            self.openCamera()
        }))

        alert.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: { _ in
            self.openGallery()
        }))

        // swiftlint:disable force_cast
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        alert.popoverPresentationController?.sourceView = sender as! UIButton
        self.present(alert, animated: true, completion: nil)
    }

    // MARK: - Open the camera
    func openCamera() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                if UIImagePickerController .isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
                    DispatchQueue.main.async {
                        self.imagePicker.sourceType = UIImagePickerController.SourceType.camera
                        self.imagePicker.allowsEditing = true
                        self.imagePicker.delegate = self
                        self.present(self.imagePicker, animated: true, completion: nil)
                    }
                }
            }
        }
    }

    // MARK: - Choose image from camera roll
    func openGallery() {
        let photos = PHPhotoLibrary.authorizationStatus()
        if photos == .notDetermined {
            PHPhotoLibrary.requestAuthorization({status in
                if status == .authorized {
                    DispatchQueue.main.async {
                        self.imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
                        self.imagePicker.allowsEditing = true
                        self.imagePicker.delegate = self
                        self.present(self.imagePicker, animated: true, completion: nil)
                    }
                }
            })
        } else if photos == .authorized {
            self.imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            self.imagePicker.allowsEditing = true
            self.imagePicker.delegate = self
            self.present(self.imagePicker, animated: true, completion: nil)
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension AccountDetailsController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.viewModel?.profilePicture = editedImage
            self.profilePicture.image = editedImage
            self.profilePicture.setRounded()
        }

        //Dismiss the UIImagePicker after selection
        picker.dismiss(animated: true, completion: nil)
    }
}
