//
//  SettingsController.swift
//  Tinitron
//
//  Created by Bartu Atabek on 5/22/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import UIKit
import Firebase

class SettingsController: UITableViewController {

    let defaults = UserDefaults.standard
    let center = UNUserNotificationCenter.current()

    @IBOutlet weak var expireNotificationsSwitch: UISwitch!
    @IBOutlet weak var deleteExpiredLinksSwitch: UISwitch!

    var viewModel: LinksViewModeling?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel = LinksViewModel()
        self.viewModel?.controller = self

        center.getNotificationSettings(completionHandler: { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                print("authorized")
            case .denied:
                self.expireNotificationsSwitch.isOn = false
                print("denied")
            case .notDetermined:
                print("not determined, ask user for permission now")
            @unknown default:
                fatalError()
            }
        })
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 4 {
            if indexPath.row == 0 {
                expireAllLinks()
            } else if indexPath.row == 1 {
                deleteAllLinks()
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - ViewController Functions
    fileprivate func expireAllLinks() {
        let alert = UIAlertController(title: nil, message: "This will expire all your links and will make them inaccessible. This operation may take some time depending on the number of links. You will be notified when it's finished.", preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Expire All Links", style: .destructive, handler: { _ in
            self.viewModel?.expireAllLinksOfUser(completion: { (finished, success) in
                if finished && success {
                    let content = UNMutableNotificationContent()
                    content.title = "All Links Expired"
                    content.subtitle = "Successfully expired all links from user account."
                    content.sound = UNNotificationSound.defaultCritical

                    // show this notification five seconds from now
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0, repeats: false)
                    // choose a random identifier
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                    // add our notification request
                    UNUserNotificationCenter.current().add(request)
                } else if finished && !success {
                    let content = UNMutableNotificationContent()
                    content.title = "Link Expiration Failed"
                    content.subtitle = "Operation failed. Please try again later."
                    content.sound = UNNotificationSound.defaultCritical

                    // show this notification five seconds from now
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0, repeats: false)
                    // choose a random identifier
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                    // add our notification request
                    UNUserNotificationCenter.current().add(request)
                }
            })
        }))

        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    fileprivate func deleteAllLinks() {
        let alert = UIAlertController(title: nil, message: "This will delete all your links and remove all your analytics data from the app. This operation may take some time depending on the number of links. You will be notified when it's finished.", preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Expire All Links", style: .destructive, handler: { _ in
            self.viewModel?.deleteAllLinksOfUser(completion: { (finished, success) in
                if finished && success {
                    let content = UNMutableNotificationContent()
                    content.title = "All Links Deleted"
                    content.subtitle = "Successfully deleted all links and analytics data from user account."
                    content.sound = UNNotificationSound.defaultCritical

                    // show this notification five seconds from now
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0, repeats: false)
                    // choose a random identifier
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                    // add our notification request
                    UNUserNotificationCenter.current().add(request)
                } else if finished && !success {
                    let content = UNMutableNotificationContent()
                    content.title = "Link Deletion Failed"
                    content.subtitle = "Operation failed. Please try again later."
                    content.sound = UNNotificationSound.defaultCritical

                    // show this notification five seconds from now
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0, repeats: false)
                    // choose a random identifier
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                    // add our notification request
                    UNUserNotificationCenter.current().add(request)
                }
            })
        }))

        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    // MARK: - Switch actions
    // Link expire notifications
    @IBAction func showLinkNotifications(_ sender: UISwitch) {
        center.getNotificationSettings(completionHandler: { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                print("authorized")
                DispatchQueue.main.async {
                    self.defaults.set(sender.isOn, forKey: Auth.auth().currentUser!.uid + "ExpireNotifications")
                }
            case .denied:
                self.expireNotificationsSwitch.isOn = false
                print("denied")
            case .notDetermined:
                print("not determined, ask user for permission now")
                self.center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, _) in
                    if granted {
                        print("User allowed notifications.")
                    } else {
                        print("User did not allow notifications.")
                    }
                }
            @unknown default:
                fatalError()
            }
        })
    }

    // Delete expired links
    @IBAction func deleteExpiredLinks(_ sender: UISwitch) {
        self.defaults.set(sender.isOn, forKey: Auth.auth().currentUser!.uid + "DeleteExpired")
    }
}
