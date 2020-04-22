//
//  AnalyticsController.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/20/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import UIKit
import Charts
import SkeletonView

// swiftlint:disable identifier_name force_cast
class AnalyticsController: UITableViewController {

    let formatter = DateFormatter()
    var selectedLink: Link?

    /// Data models for the table view.
    var sections = [[Link]]()
    var viewModel: LinksViewModeling?

    let months = ["Jan", "Feb", "Mar",
    "Apr", "May", "Jun",
    "Jul", "Aug", "Sep",
    "Oct", "Nov", "Dec"]

    @IBOutlet var chartView: CombinedChartView!

    override func viewDidLoad() {
        super.viewDidLoad()
        formatter.dateFormat = "MMM d, yyyy"
    }

    override func viewWillAppear(_ animated: Bool) {
        if viewModel != nil {
            self.viewModel?.controller = self
            selectedLink = nil
            refresh(tableView!.refreshControl!)
        }
    }

    fileprivate func getSectionsBasedOnDate(links: [Link]) -> [[Link]] {
        guard let dates = NSOrderedSet.init(array: links.map { formatter.string(from: $0.creationDate) }).array as? [String] else {
            print("Something went wrong with conversion")
            return [[Link]]()
        }

        var filteredArray = [[Link]]()

        for date in dates {
            let innerArray = links.filter({ return formatter.string(from: $0.creationDate) == date })
            filteredArray.append(innerArray)
        }

        filteredArray.sort { (section1, section2) -> Bool in
            if section1.first!.creationDate > section2.first!.creationDate {
                return true
            }
            return false
        }
        return filteredArray
    }

    fileprivate func findTrendingLinks() {
        var trendingLinks = [Link]()

        for index in 0..<sections.count {
            trendingLinks.append(contentsOf: sections[index].filter {
                if $0.isExpired { return false }
                let id = $0.shortURL

                if let linkAnalytic = viewModel!.analyticsData.first(where: { $0.id == id }) {
                    return linkAnalytic.dailyAverage >= 100
                }
                return false
            })
        }

        sections.insert(trendingLinks, at: 0)
    }

    // MARK: Refresh Control
    @IBAction func refresh(_ sender: UIRefreshControl) {
        view.showAnimatedSkeleton()
        chartView.data = nil

        viewModel?.fetchLinkAnalytics(completion: { (finished, success, fetchedAnalytics) in
            if finished && success {
                self.sections = self.getSectionsBasedOnDate(links: self.viewModel!.links)
                self.viewModel?.analyticsData = fetchedAnalytics!
                self.findTrendingLinks()
                self.setupChartView()
            }

            if finished {
                sender.endRefreshing()
                self.setupChartView()
                self.tableView.reloadData()
                self.view.hideSkeleton(transition: .crossDissolve(0.25))
            }
        })
    }
}

// MARK: - UITableViewDelegate
extension AnalyticsController {
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            if self.tableView(tableView, numberOfRowsInSection: section) > 0 {
                return "Trending Links"
            } else { return nil }
        }

        if let item = sections[section].first, self.tableView(tableView, numberOfRowsInSection: section) > 0 {
            return formatter.string(from: item.creationDate)
        } else { return nil }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedLink = sections[indexPath.section][indexPath.row]

        let detailViewController = self.storyboard?.instantiateViewController(withIdentifier: "LinkAnalytics") as! LinkAnalyticsController
        detailViewController.viewModel = viewModel
        detailViewController.analyticsData = viewModel!.analyticsData.first(where: { $0.id == selectedLink?.shortURL })
        self.splitViewController?.showDetailViewController(detailViewController, sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension AnalyticsController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LinkAnalyticsCell", for: indexPath)

        cell.textLabel?.text = sections[indexPath.section][indexPath.row].title
        cell.detailTextLabel?.text = sections[indexPath.section][indexPath.row].shortURL

        if sections[indexPath.section][indexPath.row].isExpired {
            cell.detailTextLabel?.textColor = .systemPink
            cell.imageView?.tintColor = .systemPink
            cell.imageView?.image = UIImage(systemName: "bolt.horizontal.circle")
        } else {
            cell.detailTextLabel?.textColor = .link
            let linkAnalytic = viewModel!.analyticsData.first(where: { $0.id == sections[indexPath.section][indexPath.row].shortURL })

            if linkAnalytic!.dailyAverage > 5 {
                cell.imageView?.image = UIImage(systemName: "chevron.up.circle")
                cell.imageView?.tintColor = .systemBlue
            } else {
                cell.imageView?.image = UIImage(systemName: "chevron.down.circle")
                cell.imageView?.tintColor = .systemOrange
            }
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.transform = CGAffineTransform(translationX: 0, y: 100).concatenating(CGAffineTransform(scaleX: 0.5, y: 0.5))
        cell.alpha = 0

        UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: [.curveEaseOut, .allowUserInteraction], animations: {
            cell.transform = .identity
            cell.alpha = 1

        }, completion: nil)
    }
}

extension AnalyticsController: ChartViewDelegate {
    func setupChartView() {
        chartView.delegate = self

        chartView.chartDescription?.enabled = false
        chartView.legend.enabled = false
        chartView.drawBarShadowEnabled = false
        chartView.highlightFullBarEnabled = false
        chartView.drawOrder = [DrawOrder.bar.rawValue,
                               DrawOrder.line.rawValue]

        let rightAxis = chartView.rightAxis
        rightAxis.axisMinimum = 0

        let leftAxis = chartView.leftAxis
        leftAxis.axisMinimum = 0

        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.axisMinimum = 0
        xAxis.granularity = 1
        xAxis.valueFormatter = self

        let data = CombinedChartData()
        data.lineData = generateLineData()
        data.barData = generateBarData()
        chartView.xAxis.axisMaximum = data.xMax + 0.25
        chartView.data = data
    }

    func generateLineData() -> LineChartData {
        var monthlyAverage = [Double](repeating: 0, count: 12)

        for analytics in viewModel!.analyticsData {
            monthlyAverage[0] += Double(analytics.perMonthClicks["January"]!)
            monthlyAverage[1] += Double(analytics.perMonthClicks["February"]!)
            monthlyAverage[2] += Double(analytics.perMonthClicks["March"]!)
            monthlyAverage[3] += Double(analytics.perMonthClicks["April"]!)
            monthlyAverage[4] += Double(analytics.perMonthClicks["May"]!)
            monthlyAverage[5] += Double(analytics.perMonthClicks["June"]!)
            monthlyAverage[6] += Double(analytics.perMonthClicks["July"]!)
            monthlyAverage[7] += Double(analytics.perMonthClicks["August"]!)
            monthlyAverage[8] += Double(analytics.perMonthClicks["September"]!)
            monthlyAverage[9] += Double(analytics.perMonthClicks["October"]!)
            monthlyAverage[10] += Double(analytics.perMonthClicks["November"]!)
            monthlyAverage[11] += Double(analytics.perMonthClicks["December"]!)
        }

        for index in 0..<monthlyAverage.count {
            monthlyAverage[index] /= 12
        }

        let entries = (0..<12).map { (i) -> ChartDataEntry in
            return ChartDataEntry(x: Double(i) + 0.5, y: monthlyAverage[i])
        }

        //UIColor(red: 255/255, green: 117/255, blue: 24/255, alpha: 1)
        let set = LineChartDataSet(entries: entries, label: "Line DataSet")
        set.setColor(.label)
        set.lineWidth = 2.5
        set.setCircleColor(.label)
        set.circleRadius = 5
        set.circleHoleRadius = 0
        set.mode = .cubicBezier
        set.drawValuesEnabled = false
        set.axisDependency = .right

        return LineChartData(dataSet: set)
    }

    // swiftlint:disable function_body_length
    func generateBarData() -> BarChartData {
        var monthlyTotal = [Double](repeating: 0, count: 12)
        var expiredMonthlyTotal = [Double](repeating: 0, count: 12)

        for section in sections {
            for link in section {
                if link.isExpired {
                    if let analytics = viewModel!.analyticsData.first(where: { $0.id == link.shortURL }) {
                        expiredMonthlyTotal[0] += Double(analytics.perMonthClicks["January"]!)
                        expiredMonthlyTotal[1] += Double(analytics.perMonthClicks["February"]!)
                        expiredMonthlyTotal[2] += Double(analytics.perMonthClicks["March"]!)
                        expiredMonthlyTotal[3] += Double(analytics.perMonthClicks["April"]!)
                        expiredMonthlyTotal[4] += Double(analytics.perMonthClicks["May"]!)
                        expiredMonthlyTotal[5] += Double(analytics.perMonthClicks["June"]!)
                        expiredMonthlyTotal[6] += Double(analytics.perMonthClicks["July"]!)
                        expiredMonthlyTotal[7] += Double(analytics.perMonthClicks["August"]!)
                        expiredMonthlyTotal[8] += Double(analytics.perMonthClicks["September"]!)
                        expiredMonthlyTotal[9] += Double(analytics.perMonthClicks["October"]!)
                        expiredMonthlyTotal[10] += Double(analytics.perMonthClicks["November"]!)
                        expiredMonthlyTotal[11] += Double(analytics.perMonthClicks["December"]!)
                    }
                } else {
                    if let analytics = viewModel!.analyticsData.first(where: { $0.id == link.shortURL }) {
                        monthlyTotal[0] += Double(analytics.perMonthClicks["January"]!)
                        monthlyTotal[1] += Double(analytics.perMonthClicks["February"]!)
                        monthlyTotal[2] += Double(analytics.perMonthClicks["March"]!)
                        monthlyTotal[3] += Double(analytics.perMonthClicks["April"]!)
                        monthlyTotal[4] += Double(analytics.perMonthClicks["May"]!)
                        monthlyTotal[5] += Double(analytics.perMonthClicks["June"]!)
                        monthlyTotal[6] += Double(analytics.perMonthClicks["July"]!)
                        monthlyTotal[7] += Double(analytics.perMonthClicks["August"]!)
                        monthlyTotal[8] += Double(analytics.perMonthClicks["September"]!)
                        monthlyTotal[9] += Double(analytics.perMonthClicks["October"]!)
                        monthlyTotal[10] += Double(analytics.perMonthClicks["November"]!)
                        monthlyTotal[11] += Double(analytics.perMonthClicks["December"]!)
                    }
                }
            }
        }

        let entries1 = (0..<12).map { (i) -> BarChartDataEntry in
            return BarChartDataEntry(x: 0, y: monthlyTotal[i])
        }
        let entries2 = (0..<12).map { (i) -> BarChartDataEntry in
            return BarChartDataEntry(x: 0, y: expiredMonthlyTotal[i])
        }

        let set1 = BarChartDataSet(entries: entries1, label: "Bar 1")
        set1.setColor(.systemGreen)
        set1.axisDependency = .right
        set1.drawValuesEnabled = false

        let set2 = BarChartDataSet(entries: entries2, label: "")
        set2.stackLabels = ["Stack 1", "Stack 2"]
        set2.setColor(.systemPink)
        set2.axisDependency = .right
        set2.drawValuesEnabled = false

        let groupSpace = 0.06
        let barSpace = 0.02 // x2 dataset
        let barWidth = 0.45 // x2 dataset
        // (0.45 + 0.02) * 2 + 0.06 = 1.00 -> interval per "group"

        let data = BarChartData(dataSets: [set1, set2])
        data.barWidth = barWidth

        // make this BarData object grouped
        data.groupBars(fromX: 0, groupSpace: groupSpace, barSpace: barSpace)
        return data
    }
}

extension AnalyticsController: IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return months[Int(value)]
    }
}

extension AnalyticsController: SkeletonTableViewDataSource {
    func numSections(in collectionSkeletonView: UITableView) -> Int {
        return 10
    }

    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "LinkAnalyticsCell"
    }
}
