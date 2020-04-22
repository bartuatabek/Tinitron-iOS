//
//  RoundedView.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/20/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import UIKit

@IBDesignable class RoundedView: UIView {

    @IBInspectable var leftTopRadius: CGFloat = 0 {
        didSet {
            self.applyMask()
        }
    }
    @IBInspectable var rightTopRadius: CGFloat = 0 {
        didSet {
            self.applyMask()
        }
    }
    @IBInspectable var rightBottomRadius: CGFloat = 0 {
        didSet {
            self.applyMask()
        }
    }

    @IBInspectable var leftBottomRadius: CGFloat = 0 {
        didSet {
            self.applyMask()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.applyMask()
    }

    func applyMask() {
        let shapeLayer = CAShapeLayer(layer: self.layer)
        shapeLayer.path = self.pathForCornersRounded(rect: self.bounds).cgPath
        shapeLayer.frame = self.bounds
        shapeLayer.masksToBounds = true
        self.layer.mask = shapeLayer
    }

    func pathForCornersRounded(rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0 + leftTopRadius, y: 0))
        path.addLine(to: CGPoint(x: rect.size.width - rightTopRadius, y: 0))
        path.addQuadCurve(to: CGPoint(x: rect.size.width, y: rightTopRadius), controlPoint: CGPoint(x: rect.size.width, y: 0))
        path.addLine(to: CGPoint(x: rect.size.width, y: rect.size.height - rightBottomRadius))
        path.addQuadCurve(to: CGPoint(x: rect.size.width - rightBottomRadius, y: rect.size.height), controlPoint: CGPoint(x: rect.size.width, y: rect.size.height))
        path.addLine(to: CGPoint(x: leftBottomRadius, y: rect.size.height))
        path.addQuadCurve(to: CGPoint(x: 0, y: rect.size.height - leftBottomRadius), controlPoint: CGPoint(x: 0, y: rect.size.height))
        path.addLine(to: CGPoint(x: 0, y: leftTopRadius))
        path.addQuadCurve(to: CGPoint(x: 0 + leftTopRadius, y: 0), controlPoint: CGPoint(x: 0, y: 0))
        path.close()

        return path
    }
}
