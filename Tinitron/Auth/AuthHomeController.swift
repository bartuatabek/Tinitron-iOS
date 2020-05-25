//
//  AuthHomeController.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/8/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import UIKit
import Foundation

class AuthHomeController: UIViewController {

    var viewModel: AuthViewModeling?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.overrideUserInterfaceStyle = .dark
        self.viewModel = AuthViewModel()
        self.viewModel?.controller = self

        #if targetEnvironment(macCatalyst)
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.forEach { windowScene in
            windowScene.sizeRestrictions?.minimumSize = CGSize(width: 785, height: 515)
            windowScene.sizeRestrictions?.maximumSize = CGSize(width: 785, height: 515)
        }
        #endif
    }

    override func viewDidAppear(_ animated: Bool) {
        #if targetEnvironment(macCatalyst)
        func bitSet(_ bits: [Int]) -> UInt {
            return bits.reduce(0) { $0 | (1 << $1) }
        }

        func property(_ property: String, object: NSObject, set: [Int], clear: [Int]) {
            if let value = object.value(forKey: property) as? UInt {
                object.setValue((value & ~bitSet(clear)) | bitSet(set), forKey: property)
            }
        }

        // disable full-screen button
        if  let NSApplication = NSClassFromString("NSApplication") as? NSObject.Type,
            let sharedApplication = NSApplication.value(forKeyPath: "sharedApplication") as? NSObject,
            let windows = sharedApplication.value(forKeyPath: "windows") as? [NSObject] {
            for window in windows {
                let resizable = 3
                property("styleMask", object: window, set: [], clear: [resizable])
                let fullScreenPrimary = 7
                let fullScreenAuxiliary = 8
                let fullScreenNone = 9
                property("collectionBehavior", object: window, set: [fullScreenNone], clear: [fullScreenPrimary, fullScreenAuxiliary])
            }
        }
        #endif
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if UIDevice.current.userInterfaceIdiom == .phone {
            AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        AppUtility.lockOrientation(.all)
    }

    // MARK: - Button actions
    @IBAction func goToSignUp(_ sender: Any) {
        performSegue(withIdentifier: "goToSignUp", sender: self)
    }
    @IBAction func goToSignIn(_ sender: Any) {
         performSegue(withIdentifier: "goToSignIn", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToSignUp" {
            let authSignUpController = segue.destination as? AuthSignUpController
            authSignUpController?.viewModel = viewModel
        } else if segue.identifier == "goToSignIn" {
            let authLoginController = segue.destination as? AuthSignInController
            authLoginController?.viewModel = viewModel
        }
    }
}
