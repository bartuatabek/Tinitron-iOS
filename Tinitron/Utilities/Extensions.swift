//
//  Extensions.swift
//  Neverwhere
//
//  Created by Bartu Atabek on 8/30/19.
//  Copyright © 2019 Neverwhere. All rights reserved.
//

import UIKit

// MARK: - NSObject Extensions
extension NSObject {
    var className: String {
        return NSStringFromClass(type(of: self))
    }
}

// MARK: - UIViewController Extensions
extension UIViewController {

    func customizeStatusBar() {
        // Add blur effect on status bar
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurEffectView)
        blurEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        blurEffectView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        blurEffectView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        if #available(iOS 11.0, *) {
            blurEffectView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        }
    }

    func showAlert(withTitle title: String?, message: String?, option1: String?, option2: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        if let option1 = option1, let option2 = option2 {
            alert.addAction(UIAlertAction(title: option1, style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: option2, style: .cancel, handler: { _ in
                let authStoryboard = UIStoryboard(name: "Auth", bundle: nil)
                let authResetController = authStoryboard.instantiateViewController(withIdentifier: "ResetPassword") as? AuthResetController
                authResetController?.viewModel = AuthViewModel()
                self.navigationController?.pushViewController(authResetController!, animated: true)
            }))
        } else {
            alert.addAction(UIAlertAction(title: option1, style: .cancel, handler: nil))
        }

        present(alert, animated: true, completion: nil)
    }
}

// MARK: - NavigationController Extensions
extension UINavigationController {

    func contains(viewController: UIViewController) -> Bool {
        return self.viewControllers.map { $0.className }.contains(viewController.className)
    }

    func popToViewController(ofClass: AnyClass, animated: Bool = true) -> Bool {
        if let viewController = viewControllers.filter({$0.isKind(of: ofClass)}).last {
            popToViewController(viewController, animated: animated)
            return true
        }
        return false
    }
}

// MARK: - UIColor Extensions
extension UIColor {
    convenience init(hex: String) {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }

        if (cString.count) != 6 {
            self.init(
                red: 0 / 255.0,
                green: 0 / 255.0,
                blue: 0 / 255.0,
                alpha: CGFloat(1.0)
            )
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

// MARK: - UIImageView Extensions
extension UIImageView {
    func setRounded() {
        self.layer.cornerRadius = (self.frame.width / 2) //instead of let radius = CGRectGetWidth(self.frame) / 2
        self.layer.masksToBounds = true
    }
}

// MARK: - UIView Extensions
extension UIView {
//    func dance() {
//        let pulse1 = CASpringAnimation(keyPath: "transform.scale")
//        pulse1.duration = 0.6
//        pulse1.fromValue = 1.0
//        pulse1.toValue = 1.12
//        pulse1.autoreverses = true
//        pulse1.repeatCount = 1
//        pulse1.initialVelocity = 0.5
//        pulse1.damping = 0.8
//
//        let animationGroup = CAAnimationGroup()
//        animationGroup.duration = 2.7
//        animationGroup.repeatCount = 1000
//        animationGroup.animations = [pulse1]
//        layer.add(animationGroup, forKey: "pulse")
//
//        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
//        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
//        animation.duration = 0.6
//        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0 ]
//        layer.add(animation, forKey: "shake")
//    }

    func shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0 ]
        layer.add(animation, forKey: "shake")
    }

    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}

// MARK: - NSAttributedString Extensions
extension NSAttributedString {
    static func makeHyperlink(for path: String, in string: String, as substring: String) -> NSAttributedString {
        let nsString = NSString(string: string)
        let substringRange = nsString.range(of: substring)
        let attributedString = NSMutableAttributedString(string: string)
        attributedString.addAttribute(.link, value: "view:\(path)", range: substringRange)
        return attributedString
    }
}

// MARK: - UITextView Extensions
extension UITextView {
    func centerText() {
        self.textAlignment = .center
        let fittingSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        let topOffset = (bounds.size.height - size.height * zoomScale) / 2
        let positiveTopOffset = max(1, topOffset)
        contentOffset.y = -positiveTopOffset
    }
}

// MARK: - UIImage Extensions
extension UIImage {
    func cropToBounds(width: Double, height: Double) -> UIImage {
        let cgimage = self.cgImage!
        let contextImage: UIImage = UIImage(cgImage: cgimage)
        let contextSize: CGSize = contextImage.size
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(width)
        var cgheight: CGFloat = CGFloat(height)

        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }

        let rect: CGRect = CGRect(x: posX, y: posY, width: cgwidth, height: cgheight)

        // Create bitmap image from context using the rect
        let imageRef: CGImage = cgimage.cropping(to: rect)!

        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage(cgImage: imageRef, scale: self.scale, orientation: self.imageOrientation)
        return image
    }

    func resize(toTargetSize targetSize: CGSize) -> UIImage {
        let newScale = self.scale // change this if you want the output image to have a different scale
        let originalSize = self.size

        let widthRatio = targetSize.width / originalSize.width
        let heightRatio = targetSize.height / originalSize.height

        // Figure out what our orientation is, and use that to form the rectangle
        let newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: floor(originalSize.width * heightRatio), height: floor(originalSize.height * heightRatio))
        } else {
            newSize = CGSize(width: floor(originalSize.width * widthRatio), height: floor(originalSize.height * widthRatio))
        }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(origin: .zero, size: newSize)

        // Actually do the resizing to the rect using the ImageContext stuff
        let format = UIGraphicsImageRendererFormat()
        format.scale = newScale
        format.opaque = true
        let newImage = UIGraphicsImageRenderer(bounds: rect, format: format).image { _ in
            self.draw(in: rect)
        }

        return newImage
    }
}

// MARK: - Date Extensions
extension Date {
    static func randomWithinDaysBeforeToday(_ days: Int) -> Date {
        let today = Date()
        let earliest = today.addingTimeInterval(TimeInterval(-days*24*60*60))

        return Date.random(between: earliest, and: today)
    }

    static func random() -> Date {
        let randomTime = TimeInterval(arc4random_uniform(UInt32.max))
        return Date(timeIntervalSince1970: randomTime)
    }

    static func random(between initial: Date, and final: Date) -> Date {
        let interval = final.timeIntervalSince(initial)
        let randomInterval = TimeInterval(arc4random_uniform(UInt32(interval)))
        return initial.addingTimeInterval(randomInterval)
    }
}

// MARK: - String Extensions
// swiftlint:disable force_try
extension String {
    var isValidURL: Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            // it is a link, if the match covers the whole string
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }

    var isAlphanumeric: Bool {
        return !isEmpty && range(of: "[^a-zA-Z0-9_]", options: .regularExpression) == nil
    }
}

// MARK: - UISplitViewController Extensions
extension UISplitViewController {
    convenience init(masterViewController: UIViewController, detailViewController: UIViewController) {
        self.init()
        viewControllers = [masterViewController, detailViewController]
    }

    var masterViewController: UIViewController? {
        return viewControllers.first
    }

    var detailViewController: UIViewController? {
        guard viewControllers.count == 2 else { return nil }
        return viewControllers.last
    }
}

// MARK: - UITableView Extensions
extension UITableView {
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 0
        messageLabel.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline)
        messageLabel.textAlignment = .center
        messageLabel.sizeToFit()
        self.backgroundView = messageLabel
    }

    func restore() {
        self.backgroundView = nil
    }
}
