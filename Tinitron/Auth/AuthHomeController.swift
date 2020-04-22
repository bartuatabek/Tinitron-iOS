//
//  AuthHomeController.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/8/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import UIKit

class AuthHomeController: UIViewController {

    var viewModel: AuthViewModeling?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel = AuthViewModel()
        self.viewModel?.controller = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
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
