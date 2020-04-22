//
//  XYMarkerView.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/20/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import Foundation
import Charts
#if canImport(UIKit)
    import UIKit
#endif

public class XYMarkerView: BalloonMarker {
    public var xAxisValueFormatter: IAxisValueFormatter
    fileprivate var yFormatter = NumberFormatter()

    public init(color: UIColor, font: UIFont, textColor: UIColor, insets: UIEdgeInsets,
                xAxisValueFormatter: IAxisValueFormatter) {
        self.xAxisValueFormatter = xAxisValueFormatter
        yFormatter.minimumFractionDigits = 1
        yFormatter.maximumFractionDigits = 1
        super.init(color: color, font: font, textColor: textColor, insets: insets)
    }

    //swiftlint:disable compiler_protocol_init
    public override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        let string = yFormatter.string(from: NSNumber(floatLiteral: entry.y))!
        setLabel(string)
    }

}
