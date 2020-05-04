//
//  LinkAnalytics.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/20/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import Foundation

struct LinkAnalytics {

    var title: String?
    var id: String

    // Highlights
    var lastAccessDate: Date?
    var dailyAverage: Double

    // Range
    var max: Int64
    var min: Int64

    // Yearly Highlights
    var totalPerYear: Int64

    // Monthly Highlights
    var perMonthClicks: [String: Int64] = ["January": 0,
                                        "February": 0,
                                        "March": 0,
                                        "April": 0,
                                        "May": 0,
                                        "June": 0,
                                        "July": 0,
                                        "August": 0,
                                        "September": 0,
                                        "October": 0,
                                        "November": 0,
                                        "December": 0]

    // Browser Highlights
    var browserCounts: [String: Int64] = ["ie": 0,
                                       "firefox": 0,
                                       "chrome": 0,
                                       "opera": 0,
                                       "safari": 0,
                                       "others": 0]

    // OS Highlights
    var osCounts: [String: Int64] = ["windows": 0,
                                  "macOs": 0,
                                  "linux": 0,
                                  "android": 0,
                                  "ios": 0,
                                  "others": 0]

    init(title: String? = nil, id: String, lastAccessDate: Date?, dailyAverage: Double, max: Int64, min: Int64, totalPerYear: Int64, perMonthClicks: [String: Int64], browserCounts: [String: Int64], osCounts: [String: Int64]) {
        self.title = title
        self.id = id
        self.lastAccessDate = lastAccessDate
        self.dailyAverage = dailyAverage
        self.max = max
        self.min = min
        self.totalPerYear = totalPerYear
        self.perMonthClicks = perMonthClicks
        self.browserCounts = browserCounts
        self.osCounts = osCounts
    }
}
