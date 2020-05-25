//
//  QRCodeController.swift
//  Tinitron
//
//  Created by Bartu Atabek on 5/23/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import UIKit

class QRCodeController: UIViewController {

    var shortURL: String?

    @IBOutlet weak var qrCodeImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let shortURL = shortURL {
            qrCodeImageView.image = generateQRCode(from: "http://tinitron.ml/" + shortURL)
        }
    }

    fileprivate func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 10, y: 10)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }

        return nil
    }

    // MARK: - Button Actions
    @IBAction func dismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func shareQRCode(_ sender: Any) {
        if let qrCode = qrCodeImageView.image {
            let items: [Any] = [qrCode]

            let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)
            activityController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
            present(activityController, animated: true)
        }
    }
}
