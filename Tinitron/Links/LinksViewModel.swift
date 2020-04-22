//
//  LinksViewModel.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/21/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import Alamofire
import Foundation
import SwiftyJSON

protocol LinksViewModeling {
    var controller: UIViewController? { get set }

    var links: [Link] { get set }
    var analyticsData: [LinkAnalytics] { get set }

    func createNewLink(for link: Link, completion: @escaping (Bool, Bool, Link?) -> Void)
    func updateLink(link: Link, completion: @escaping (Bool, Bool) -> Void)
    func deleteLinks(links: [String], completion: @escaping (Bool, Bool) -> Void)
    func expireLinks(links: [String], completion: @escaping (Bool, Bool) -> Void)

    func fetchLinks(completion: @escaping (Bool, Bool, [Link]?) -> Void)
    func fetchLink(shortURL: String, completion: @escaping (Bool, Bool, Link?) -> Void)

    func fetchLinkAnalytics(completion: @escaping (Bool, Bool, [LinkAnalytics]?) -> Void)
    func fetchLinkAnalytic(for link: String, completion: @escaping (Bool, Bool, LinkAnalytics?) -> Void)
}

class LinksViewModel: LinksViewModeling {

    // MARK: - Properties
    weak var controller: UIViewController?

    var links: [Link]
    var analyticsData: [LinkAnalytics]

    // MARK: - Initialization
    init() {
        links = generateRandomLinks(count: 100)
        analyticsData = generateAllAnalytics(for: links)
    }

    func createNewLink(for link: Link, completion: @escaping (Bool, Bool, Link?) -> Void) {
        // TODO: Create and save link

        let originalURL = "https://www.\(randomWord()).com"
        let title = Bool.random() ? originalURL : randomWord() + " " + randomWord()
        let creationDate = Date.randomWithinDaysBeforeToday(14)
        let expirationDate = Bool.random() ?Calendar.current.date(byAdding: .day, value: -5, to: Date()) : Calendar.current.date(byAdding: .day, value: 30, to: creationDate)
        let link = Link(title: title, creationDate: creationDate, originalURL: originalURL, shortURL: "tinytron.ml/\(randomString(length: 7))", expirationDate: expirationDate!, password: nil)

        analyticsData.append(generateRandomLinkAnalytics(id: link.shortURL))
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completion(true, true, link)
        }
    }

    func updateLink(link: Link, completion: @escaping (Bool, Bool) -> Void) {
        // TODO: Call API to update Link

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(true, true)
        }
    }

    func deleteLinks(links: [String], completion: @escaping (Bool, Bool) -> Void) {
        // TODO: Call API to delete links

        for link in links {
            let index = analyticsData.firstIndex(where: { $0.id == link })
            analyticsData.remove(at: index!)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(true, true)
        }
    }

    func expireLinks(links: [String], completion: @escaping (Bool, Bool) -> Void) {
        // TODO: Call API to expire links

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(true, true)
        }
    }

    // MARK: - Fetch Link Data
    func fetchLinks(completion: @escaping (Bool, Bool, [Link]?) -> Void) {
        // TODO: Refresh links from API

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completion(true, true, self.links)
        }
    }

    func fetchLink(shortURL: String, completion: @escaping (Bool, Bool, Link?) -> Void) {
        // TODO: Refresh link information from API

        let link = links.first(where: { $0.shortURL == shortURL })
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completion(true, true, link)
        }
    }

    // MARK: - Fetch Analytics Data
    func fetchLinkAnalytics(completion: @escaping (Bool, Bool, [LinkAnalytics]?) -> Void) {
        // TODO: Refresh link analytics from API
        analyticsData = generateAllAnalytics(for: links)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(true, true, self.analyticsData)
        }
    }

    func fetchLinkAnalytic(for link: String, completion: @escaping (Bool, Bool, LinkAnalytics?) -> Void) {
        // TODO: Refresh link analytic information from API

        let analytics = analyticsData.first(where: { $0.id == link })
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(true, true, analytics)
        }
    }
}
