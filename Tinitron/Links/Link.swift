//
//  Link.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/11/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import Foundation

struct Link: Equatable {

    // URL Information
    var title: String
    var creationDate: Date

    // URL Properties
    var originalURL: String
    var shortURL: String

    // URL Customizations
    var expirationDate: Date
    var password: String?
    var maxAllowedClicks: Int?

    init(title: String, creationDate: Date = Date(), originalURL: String, shortURL: String, expirationDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date())!, password: String?, maxAllowedClicks: Int? = -1) {
        self.title = title
        self.creationDate = creationDate
        self.originalURL = originalURL
        self.shortURL = shortURL
        self.expirationDate = expirationDate
        self.password = password
        self.maxAllowedClicks = maxAllowedClicks
    }

    var daysUntilExpiration: Int {
        return Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day!
    }

    var isExpired: Bool {
        return daysUntilExpiration <= 0
    }

    static func == (lhs: Link, rhs: Link) -> Bool {
        return lhs.shortURL == rhs.shortURL
    }
}
