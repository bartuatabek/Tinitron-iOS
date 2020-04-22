//
//  LinkAnalyticsController.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/20/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import UIKit
import Charts

class LinkAnalyticsController: UITableViewController {

    let numberFormatter = NumberFormatter()
    let dateFormatter = DateFormatter()

    /// Data models for the table view.
    var analyticsData: LinkAnalytics?
    var viewModel: LinksViewModeling?

    @IBOutlet weak var lastAccessDateLabel: UILabel!
    @IBOutlet weak var dailyAverageLabel: UILabel!

    @IBOutlet weak var maxClicksLabel: UILabel!
    @IBOutlet weak var maxClicksChart: RoundedView!

    @IBOutlet weak var minClicksLabel: UILabel!
    @IBOutlet weak var minClicksChart: RoundedView!

    @IBOutlet weak var totalPerYearLabel: UILabel!
    @IBOutlet var monthlyClicksChartView: BarChartView!

    @IBOutlet var browsersChartView: PieChartView!
    @IBOutlet var osChartView: PieChartView!

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel?.controller = self

        dateFormatter.dateFormat = "MM/dd/yyyy"
        numberFormatter.numberStyle = .decimal

        setupTableInformation()
        setupMonthlyClicksChartView()

        setupBrowserChartView()
        setupOSChartView()
    }

    // MARK: Refresh Control
    @IBAction func refresh(_ sender: UIRefreshControl) {
        view.showAnimatedSkeleton()
        monthlyClicksChartView.data = nil
        browsersChartView.data = nil
        browsersChartView.data = nil

        viewModel?.fetchLinkAnalytic(for: analyticsData!.id, completion: { (finished, success, fetchedAnalytics) in
            if finished && success {
                self.analyticsData = fetchedAnalytics
            }

            if finished {
                sender.endRefreshing()
                self.tableView.reloadData()
                self.setupTableInformation()
                self.setupMonthlyClicksChartView()
                self.setupBrowserChartView()
                self.setupOSChartView()
                self.view.hideSkeleton(transition: .crossDissolve(0.25))
            }
        })
    }

    fileprivate func setupTableInformation() {
        lastAccessDateLabel.text = dateFormatter.string(from: analyticsData!.lastAccessDate)
        dailyAverageLabel.text = numberFormatter.string(from: NSNumber(value: analyticsData!.dailyAverage))

        maxClicksLabel.text = numberFormatter.string(from: NSNumber(value: analyticsData!.max))
        minClicksLabel.text = numberFormatter.string(from: NSNumber(value: analyticsData!.min))

        maxClicksChart.widthAnchor.constraint(equalToConstant: analyticsData!.max > 300 ? CGFloat(analyticsData!.max/2) : CGFloat(analyticsData!.max)).isActive = true
        minClicksChart.widthAnchor.constraint(equalToConstant: analyticsData!.min > 300 ? CGFloat(analyticsData!.min/2) : CGFloat(analyticsData!.max)).isActive = true

        totalPerYearLabel.text = "The total number of clicks per year for this link is \(numberFormatter.string(from: NSNumber(value: analyticsData!.totalPerYear)) ?? "null")."
    }
}

// swiftlint:disable function_body_length
extension LinkAnalyticsController: ChartViewDelegate {
    func setup(barLineChartView chartView: BarLineChartViewBase) {
        chartView.chartDescription?.enabled = false

        chartView.dragEnabled = true
        chartView.setScaleEnabled(false)
        chartView.pinchZoomEnabled = false

        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom

        chartView.rightAxis.enabled = false
        chartView.legend.enabled = false
    }

    func setup(pieChartView chartView: PieChartView) {
        chartView.usePercentValuesEnabled = true
        chartView.drawSlicesUnderHoleEnabled = false
        chartView.holeRadiusPercent = 0.58
        chartView.transparentCircleRadiusPercent = 0.61
        chartView.chartDescription?.enabled = false

        chartView.drawCenterTextEnabled = true
        chartView.holeColor = .systemBackground

        chartView.drawHoleEnabled = true
        chartView.rotationAngle = 0
        chartView.rotationEnabled = true
        chartView.highlightPerTapEnabled = true
        chartView.legend.enabled = false
    }

    func setupMonthlyClicksChartView() {
        self.setup(barLineChartView: monthlyClicksChartView)

        monthlyClicksChartView.delegate = self
        monthlyClicksChartView.drawBarShadowEnabled = false
        monthlyClicksChartView.drawValueAboveBarEnabled = false

        monthlyClicksChartView.maxVisibleCount = 60

        let xAxis = monthlyClicksChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.granularity = 1
        xAxis.labelCount = 12
        xAxis.valueFormatter = DayAxisValueFormatter(chart: monthlyClicksChartView)

        monthlyClicksChartView.leftAxis.enabled = false
        monthlyClicksChartView.leftAxis.axisMinimum = 0

        let rightAxisFormatter = NumberFormatter()
        rightAxisFormatter.minimumFractionDigits = 0
        rightAxisFormatter.maximumFractionDigits = 1

        let rightAxis = monthlyClicksChartView.rightAxis
        rightAxis.enabled = true
        rightAxis.labelFont = .systemFont(ofSize: 10)
        rightAxis.labelCount = 4
        rightAxis.valueFormatter = DefaultAxisValueFormatter(formatter: rightAxisFormatter)
        rightAxis.labelPosition = .outsideChart
        rightAxis.spaceTop = 0.15
        rightAxis.axisMinimum = 0

        let marker = XYMarkerView(color: UIColor.secondarySystemBackground,
                                  font: .systemFont(ofSize: 12),
                                  textColor: .secondaryLabel,
                                  insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8),
                                  xAxisValueFormatter: monthlyClicksChartView.xAxis.valueFormatter!)
        marker.chartView = monthlyClicksChartView
        marker.minimumSize = CGSize(width: 80, height: 40)
        monthlyClicksChartView.marker = marker

        let keys = Array((analyticsData?.perMonthClicks.keys)!)
        var monthlyEntries = [BarChartDataEntry]()

        for index in 0..<12 {
            let value = BarChartDataEntry(x: Double(index), y: Double((analyticsData?.perMonthClicks[keys[index]])!))
            monthlyEntries.append(value)
        }

        var set1: BarChartDataSet! = nil
        if let set = monthlyClicksChartView.data?.dataSets.first as? BarChartDataSet {
            set1 = set
            set1.replaceEntries(monthlyEntries)
            monthlyClicksChartView.data?.notifyDataChanged()
            monthlyClicksChartView.notifyDataSetChanged()
        } else {
            set1 = BarChartDataSet(entries: monthlyEntries, label: "Montly Clicks")
            set1.colors = [UIColor.systemTeal, UIColor.systemPink, UIColor.systemGreen, UIColor.midnightBlue, UIColor.peterRiver, UIColor.systemOrange, UIColor.systemRed, UIColor.sunFlower, UIColor.systemPurple, UIColor.pumpkin, UIColor.brown, UIColor.silver]
            set1.drawValuesEnabled = false

            let data = BarChartData(dataSet: set1)
            data.setValueFont(UIFont(name: "HelveticaNeue-Light", size: 10)!)
            data.barWidth = 0.9
            monthlyClicksChartView.data = data
        }
    }

    func setupBrowserChartView() {
        self.setup(pieChartView: browsersChartView)
        browsersChartView.delegate = self

        // entry label styling
        browsersChartView.entryLabelColor = .white
        browsersChartView.entryLabelFont = .systemFont(ofSize: 12, weight: .semibold)
        browsersChartView.animate(xAxisDuration: 1.4, easingOption: .easeOutBack)

        let keys = Array((analyticsData?.browserCounts.keys)!)
        var browserEntries = [PieChartDataEntry]()

        for index in 0..<6 {
            let value = PieChartDataEntry(value: Double((analyticsData?.browserCounts[keys[index]])!),
                                          label: keys[index].capitalized,
                                          icon: nil)
            browserEntries.append(value)
        }

        let set = PieChartDataSet(entries: browserEntries, label: "Browsers")
        set.drawIconsEnabled = false
        set.sliceSpace = 2

        set.colors = [UIColor.systemPink, UIColor.systemBlue, UIColor.systemTeal, UIColor.systemPurple, UIColor.systemIndigo, UIColor.systemGreen]
        let data = PieChartData(dataSet: set)

        let pFormatter = NumberFormatter()
        pFormatter.numberStyle = .percent
        pFormatter.maximumFractionDigits = 1
        pFormatter.multiplier = 1
        pFormatter.percentSymbol = " %"
        data.setValueFormatter(DefaultValueFormatter(formatter: pFormatter))

        data.setValueFont(.systemFont(ofSize: 11, weight: .semibold))
        data.setValueTextColor(.white)

        browsersChartView.data = data
        browsersChartView.highlightValues(nil)

        // swiftlint:disable force_cast
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.alignment = .center

        let centerText = NSMutableAttributedString(string: "Browser \nTypes", attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        browsersChartView.centerAttributedText = centerText
    }

    func setupOSChartView() {
        self.setup(pieChartView: osChartView)
        osChartView.delegate = self

        // entry label styling
        osChartView.entryLabelColor = .white
        osChartView.entryLabelFont = .systemFont(ofSize: 12, weight: .semibold)
        osChartView.animate(xAxisDuration: 1.4, easingOption: .easeOutBack)

        let keys = Array((analyticsData?.osCounts.keys)!)
        var browserEntries = [PieChartDataEntry]()

        for index in 0..<6 {
            let value = PieChartDataEntry(value: Double((analyticsData?.osCounts[keys[index]])!),
                                          label: keys[index].capitalized,
                                          icon: nil)
            browserEntries.append(value)
        }

        let set = PieChartDataSet(entries: browserEntries, label: "Browsers")
        set.drawIconsEnabled = false
        set.sliceSpace = 2

        set.colors = ChartColorTemplates.colorful() + [UIColor.systemGray]
        let data = PieChartData(dataSet: set)

        let pFormatter = NumberFormatter()
        pFormatter.numberStyle = .percent
        pFormatter.maximumFractionDigits = 1
        pFormatter.multiplier = 1
        pFormatter.percentSymbol = " %"
        data.setValueFormatter(DefaultValueFormatter(formatter: pFormatter))

        data.setValueFont(.systemFont(ofSize: 11, weight: .semibold))
        data.setValueTextColor(.white)

        osChartView.data = data
        osChartView.highlightValues(nil)

        // swiftlint:disable force_cast
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.alignment = .center

        let centerText = NSMutableAttributedString(string: "Operating System \nTypes", attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        osChartView.centerAttributedText = centerText
    }
}
