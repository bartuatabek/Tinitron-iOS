//
//  AppDelegate.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/7/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import UIKit
import Firebase
import IQKeyboardManagerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        // MARK: IQKeyboardMangager Config
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        IQKeyboardManager.shared.shouldShowToolbarPlaceholder = false
        IQKeyboardManager.shared.disabledDistanceHandlingClasses.append(UINavigationController.self)

        // MARK: Firebase Auth Config
        FirebaseApp.configure()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)

        builder.remove(menu: .services)
        builder.remove(menu: .format)
        builder.remove(menu: .toolbar)

        let helpCommand = UIKeyCommand(title: "Tinitron Help", action: #selector(showHelp), input: "")
        let helpMenu = UIMenu(title: "Tinitron Help", image: nil, identifier: UIMenu.Identifier("help"), options: .displayInline, children: [helpCommand])
        builder.replaceChildren(ofMenu: .help) { (_) -> [UIMenuElement] in
            return [helpMenu]
        }
    }

    @objc private func showHelp() {
         UIApplication.shared.open(URL(string: "https://tinitron.cf")!)
    }

    @objc private func createLink() {

    }
}
