//
//  SceneDelegate.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/7/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import UIKit
import Firebase

// swiftlint:disable unused_optional_binding force_cast
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        guard let currentUser = Auth.auth().currentUser else { return }

        let defaults = UserDefaults.standard
        if let isNewUser = defaults.string(forKey: currentUser.uid), isNewUser == "false" {
            let homeStoryboard = UIStoryboard(name: "Home", bundle: nil)
            let homeController = homeStoryboard.instantiateViewController(identifier: "HomeTabBarController") as UITabBarController

            if let windowScene = scene as? UIWindowScene {
                self.window = UIWindow(windowScene: windowScene)
                self.window!.rootViewController = homeController
                self.window!.makeKeyAndVisible()

                switch defaults.integer(forKey: "appearance") {
                case 0:
                    window!.overrideUserInterfaceStyle = .unspecified
                case 1:
                    window!.overrideUserInterfaceStyle = .light
                default:
                    window!.overrideUserInterfaceStyle = .dark
                }
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let defaults = UserDefaults.standard
        guard let currentUser = Auth.auth().currentUser else { return }
        if let isNewUser = defaults.string(forKey: currentUser.uid), isNewUser == "true" {
            return
        }

        switch shortcutItem.type {
        case "ml.tinitron.shorten":
             if let tabBarController = self.window!.rootViewController as? UITabBarController {
                tabBarController.selectedIndex = 0
                let navigationController = tabBarController.selectedViewController as! UINavigationController
                navigationController.viewControllers.first?.performSegue(withIdentifier: "goToCreateLink", sender: nil)
             }
        case "ml.tinitron.trending":
            if let tabBarController = self.window!.rootViewController as? UITabBarController {
                   tabBarController.selectedIndex = 1
            }
        default:
            break
        }
    }
}
