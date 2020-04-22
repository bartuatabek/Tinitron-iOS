//
//  FormTextField.swift
//  Neverwhere
//
//  Created by Bartu Atabek on 8/30/19.
//  Copyright © 2019 Neverwhere. All rights reserved.
//

import UIKit

@IBDesignable class FormTextField: UITextField {

    enum LinePosition {
        case top, bottom
    }

    @IBInspectable var rightImage: UIImage? {
        didSet {
            updateView()
        }
    }

    @IBInspectable var bottomBorderColor: UIColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1.0) {
        didSet {
            setBottomBorder(borderColor: bottomBorderColor)
        }
    }

    @IBInspectable var showIndicator: Bool = false {
        didSet {
            updateView()
        }
    }

    func updateView() {
        if showIndicator {
            let activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator.startAnimating()
            rightView = activityIndicator
            rightViewMode = UITextField.ViewMode.always
        } else if let image = rightImage {
            let imageView = UIImageView(image: image)
            if let size = imageView.image?.size {
                imageView.frame = CGRect(x: 0.0, y: 0.0, width: size.width + 10.0, height: size.height)
            }
            imageView.contentMode = UIView.ContentMode.center
            rightView = imageView
            rightViewMode = UITextField.ViewMode.always
        } else {
            rightViewMode = .never
            rightView = nil
        }
    }

    func setBottomBorder(borderColor: UIColor) {
        addLine(position: .bottom, color: borderColor, width: 2.0)
    }

    func addLine(position: LinePosition, color: UIColor, width: Double) {
        let lineView = UIView()
        lineView.backgroundColor = color
        lineView.translatesAutoresizingMaskIntoConstraints = false // This is important!
        self.addSubview(lineView)

        let metrics = ["width": NSNumber(value: width)]
        let views = ["lineView": lineView]
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[lineView]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))

        switch position {
        case .top:
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[lineView(width)]", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        case .bottom:
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[lineView(width)]|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: metrics, views: views))
        }
    }
}
