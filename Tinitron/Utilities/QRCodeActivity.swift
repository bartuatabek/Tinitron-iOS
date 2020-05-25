//
//  QRCodeActivity.swift
//  Tinitron
//
//  Created by Bartu Atabek on 5/23/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import UIKit

// swiftlint:disable identifier_name
class QRCodeActivity: UIActivity {

    var _activityTitle: String
    var _activityImage: UIImage?
    var activityItems = [Any]()
    var action: ([Any]) -> Void

    init(title: String, image: UIImage?, performAction: @escaping ([Any]) -> Void) {
        _activityTitle = title
        _activityImage = image
        action = performAction
        super.init()
    }

    override var activityTitle: String? {
        return _activityTitle
    }

    override var activityImage: UIImage? {
        return _activityImage
    }

    override var activityType: UIActivity.ActivityType? {
        return UIActivity.ActivityType(rawValue: "cf.infinitus.Tinitron.qrCode")
    }

    override class var activityCategory: UIActivity.Category {
        return .action
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }

    override func prepare(withActivityItems activityItems: [Any]) {
        self.activityItems = activityItems
    }

    override func perform() {
        action(activityItems)
        activityDidFinish(true)
    }
}
