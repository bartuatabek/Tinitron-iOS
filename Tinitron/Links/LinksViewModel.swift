//
//  LinksViewModel.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/21/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import Firebase
import Alamofire
import Foundation
import SwiftyJSON

protocol LinksViewModeling {
    var controller: UIViewController? { get set }

    var links: [Link] { get set }
    var analyticsData: [LinkAnalytics] { get set }

    func createNewLink(for link: Link, completion: @escaping (Bool, Bool, Link?) -> Void)
    func updateLink(shortURL: String, link: Link, completion: @escaping (Bool, Bool) -> Void)
    func deleteLinks(links: [String], completion: @escaping (Bool, Bool) -> Void)
    func expireLinks(links: [String], completion: @escaping (Bool, Bool) -> Void)

    func fetchLinks(pageNo: Int, completion: @escaping (Bool, Bool, Int, Int, [Link]?) -> Void)
    func fetchLink(shortURL: String, completion: @escaping (Bool, Bool, Link?) -> Void)

    func fetchLinkAnalytics(pageNo: Int, completion: @escaping (Bool, Bool, Int, Int, [LinkAnalytics]?) -> Void)
    func fetchLinkAnalytic(for link: String, completion: @escaping (Bool, Bool, LinkAnalytics?) -> Void)
}

class LinksViewModel: LinksViewModeling {

    // MARK: - Properties
    weak var controller: UIViewController?

    var links: [Link]
    var analyticsData: [LinkAnalytics]

    // MARK: - Initialization
    init() {
        links = [Link]() //generateRandomLinks(count: 100)
        analyticsData = [LinkAnalytics]() //generateAllAnalytics(for: links)
    }

    func createNewLink(for link: Link, completion: @escaping (Bool, Bool, Link?) -> Void) {
        let currentUser = Auth.auth().currentUser
        currentUser?.getIDTokenForcingRefresh(true) { idToken, error in
            if let error = error {
                print("Cannot get token: ", error )
                return
            }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions.insert(.withFractionalSeconds)

            var parameters: [String: String?] = [
                "title": link.title,
                "originalURL": link.originalURL,
                "creationDate": formatter.string(from: link.creationDate),
                "expirationDate": formatter.string(from: link.expirationDate)
            ]

            if !link.shortURL.isEmpty {
                parameters["shortURL"] = link.shortURL
            }

            if !link.password!.isEmpty {
                parameters["password"] = link.password
            }

            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(idToken ?? "")"
            ]

            AF.request("http://34.67.248.87:8080/links", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default, headers: headers)
                .validate(statusCode: 200..<300)
                .responseJSON { response in
//                    debugPrint(response)
                    switch response.result {
                    case .success(let value):
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

                        let json = JSON(value)
                        let title = json["title"].rawString()
                        let creationDate = dateFormatter.date(from: json["creationDate"].rawString()!)
                        let shortURL = json["shortURL"].rawString()
                        let originalURL = json["originalURL"].rawString()
                        let expirationDate = dateFormatter.date(from: json["expirationDate"].rawString()!)
                        let password = json["password"].rawString() == "null" ? nil : json["password"].rawString()

                        let link = Link(title: title!, creationDate: creationDate!, originalURL: originalURL!, shortURL: shortURL!, expirationDate: expirationDate!, password: password)
                        completion(true, true, link)
                    case .failure(let error):
                        print(error)
                        self.controller?.showAlert(withTitle: "Link Generation Failed", message: error.localizedDescription, option1: "OK", option2: nil)
                        completion(true, false, nil)
                    }
            }
        }
    }

    func updateLink(shortURL: String, link: Link, completion: @escaping (Bool, Bool) -> Void) {
        let currentUser = Auth.auth().currentUser
        currentUser?.getIDTokenForcingRefresh(true) { idToken, error in
            if let error = error {
                print("Cannot get token: ", error )
                return
            }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions.insert(.withFractionalSeconds)

            var parameters: [String: String?] = [
                "title": link.title,
                "shortURL": link.shortURL,
                "expirationDate": formatter.string(from: link.expirationDate)
            ]

            if let password = link.password {
                parameters["password"] = password
            }

            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(idToken ?? "")"
            ]

            AF.request("http://34.67.248.87:8080/links/" + shortURL, method: .put, parameters: parameters, encoder: JSONParameterEncoder.default, headers: headers)
                .validate(statusCode: 200..<300)
                .responseJSON { response in
//                    debugPrint(response)
                    switch response.result {
                    case .success:
                        completion(true, true)
                    case .failure(let error):
                        print(error)
                        self.controller?.showAlert(withTitle: "Update Failed", message: error.localizedDescription, option1: "OK", option2: nil)
                        completion(true, false)
                    }
            }
        }
    }

    func deleteLinks(links: [String], completion: @escaping (Bool, Bool) -> Void) {
        let currentUser = Auth.auth().currentUser
        currentUser?.getIDTokenForcingRefresh(true) { idToken, error in
            if let error = error {
                print("Cannot get token: ", error )
                return
            }

            let parameters: [String: [String]] = [
                "links": links
            ]

            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(idToken ?? "")"
            ]

            AF.request("http://34.67.248.87:8080/links/delete", method: .delete, parameters: parameters, encoder: JSONParameterEncoder.default, headers: headers)
                .validate(statusCode: 200..<300)
                .responseJSON { response in
//                    debugPrint(response)
                    switch response.result {
                    case .success:
                        completion(true, true)
                    case .failure(let error):
                        print(error)
                        self.controller?.showAlert(withTitle: "Deletion Failed", message: error.localizedDescription, option1: "OK", option2: nil)
                        completion(true, false)
                    }
            }
        }
    }

    func expireLinks(links: [String], completion: @escaping (Bool, Bool) -> Void) {
        let currentUser = Auth.auth().currentUser
        currentUser?.getIDTokenForcingRefresh(true) { idToken, error in
            if let error = error {
                print("Cannot get token: ", error )
                return
            }

            let parameters: [String: [String]] = [
                "links": links
            ]

            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(idToken ?? "")"
            ]

            AF.request("http://34.67.248.87:8080/links/expire", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default, headers: headers)
                .validate(statusCode: 200..<300)
                .responseJSON { response in
//                    debugPrint(response)
                    switch response.result {
                    case .success:
                        completion(true, true)
                    case .failure(let error):
                        print(error)
                        self.controller?.showAlert(withTitle: "Operation Failed", message: error.localizedDescription, option1: "OK", option2: nil)
                        completion(true, false)
                    }
            }
        }
    }

    // MARK: - Fetch Link Data
    func fetchLinks(pageNo: Int, completion: @escaping (Bool, Bool, Int, Int, [Link]?) -> Void) {
        let currentUser = Auth.auth().currentUser
        currentUser?.getIDTokenForcingRefresh(true) { idToken, error in
            if let error = error {
                print("Cannot get token: ", error )
                return
            }

            let parameters: Parameters = [
                "pageNo": pageNo
            ]

            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(idToken ?? "")"
            ]

            AF.request("http://34.67.248.87:8080/links/users/" + currentUser!.uid, method: .get, parameters: parameters, headers: headers)
                .validate(statusCode: 200..<300)
                .responseJSON { response in
//                    debugPrint(response)
                    switch response.result {
                    case .success(let value):
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                        var fetchedLinks = [Link]()

                        let json = JSON(value)
                        let pageNumber = json["pageNumber"].intValue
                        let totalPages = json["totalPages"].intValue

                        let links = json["linkDTOList"].arrayValue
                        for link in links {
                            let title = link["title"].rawString() == "null" ? link["originalURL"].rawString() : link["title"].rawString()
                            let creationDate = dateFormatter.date(from: link["creationDate"].rawString()!)
                            let shortURL = link["shortURL"].rawString()
                            let originalURL = link["originalURL"].rawString()
                            let expirationDate = dateFormatter.date(from: link["expirationDate"].rawString()!)
                            let password = link["password"].rawString() == "null" ? nil : link["password"].rawString()
                            let fetchedLink = Link(title: title!, creationDate: creationDate!, originalURL: originalURL!, shortURL: shortURL!, expirationDate: expirationDate!, password: password)
                            fetchedLinks.append(fetchedLink)
                        }

                        completion(true, true, pageNumber, totalPages, fetchedLinks)
                    case .failure(let error):
                        print(error)
                        self.controller?.showAlert(withTitle: "Fetch Failed", message: error.localizedDescription, option1: "OK", option2: nil)
                        completion(true, false, 0, 0, nil)
                    }
            }
        }
    }

    func fetchLink(shortURL: String, completion: @escaping (Bool, Bool, Link?) -> Void) {
        let currentUser = Auth.auth().currentUser
        currentUser?.getIDTokenForcingRefresh(true) { idToken, error in
            if let error = error {
                print("Cannot get token: ", error )
                return
            }

            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(idToken ?? "")"
            ]

            AF.request("http://34.67.248.87:8080/links/" + shortURL, method: .get, headers: headers)
                .validate(statusCode: 200..<300)
                .responseJSON { response in
                    //debugPrint(response)
                    switch response.result {
                    case .success(let value):
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

                        let json = JSON(value)
                        let title = json["title"].rawString() == "null" ? json["originalURL"].rawString() : json["title"].rawString()
                        let creationDate = dateFormatter.date(from: json["creationDate"].rawString()!)
                        let shortURL = json["shortURL"].rawString()
                        let originalURL = json["originalURL"].rawString()
                        let expirationDate = dateFormatter.date(from: json["expirationDate"].rawString()!)
                        let password = json["password"].rawString() == "null" ? nil : json["password"].rawString()

                        let link = Link(title: title!, creationDate: creationDate!, originalURL: originalURL!, shortURL: shortURL!, expirationDate: expirationDate!, password: password)
                        completion(true, true, link)
                    case .failure(let error):
                        print(error)
                        self.controller?.showAlert(withTitle: "Fetch Failed", message: error.localizedDescription, option1: "OK", option2: nil)
                        completion(true, false, nil)
                    }
            }
        }
    }

    // MARK: - Fetch Analytics Data
    func fetchLinkAnalytics(pageNo: Int, completion: @escaping (Bool, Bool, Int, Int, [LinkAnalytics]?) -> Void) {
        let currentUser = Auth.auth().currentUser
        currentUser?.getIDTokenForcingRefresh(true) { idToken, error in
            if let error = error {
                print("Cannot get token: ", error )
                return
            }

            let parameters: Parameters = [
                "pageNo": pageNo
            ]

            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(idToken ?? "")"
            ]

            AF.request("http://35.222.149.45:8080/analytics/users/" + currentUser!.uid, method: .get, parameters: parameters, headers: headers)
                .validate(statusCode: 200..<300)
                .responseJSON { response in
//                    debugPrint(response)
                    switch response.result {
                    case .success(let value):
                        var fetchedAnalytics = [LinkAnalytics]()

                        let json = JSON(value)
                        let pageNumber = json["pageNumber"].intValue
                        let totalPages = json["totalPages"].intValue

                        let analytics = json["analyticsDTOList"].arrayValue
                        for analytic in analytics {
                            let id = analytic["shortURL"].rawString()
                            let perMonthClicks = analytic["perMonth"].dictionaryObject as? [String: Int64]

                            let dailyAverage = 0.0
                            let max = Int64(0)
                            let min = Int64(0)
                            let totalPerYear = Int64(0)
                            let browserCounts = [String: Int64]()
                            let osCounts =  [String: Int64]()

                            let fetchedAnalytic = LinkAnalytics(id: id!, lastAccessDate: nil, dailyAverage: dailyAverage, max: max, min: min, totalPerYear: totalPerYear, perMonthClicks: perMonthClicks!, browserCounts: browserCounts, osCounts: osCounts)
                            fetchedAnalytics.append(fetchedAnalytic)
                        }

                        completion(true, true, pageNumber, totalPages, fetchedAnalytics)
                    case .failure(let error):
                        print(error)
                        self.controller?.showAlert(withTitle: "Fetch Failed", message: error.localizedDescription, option1: "OK", option2: nil)
                        completion(true, false, 0, 0, nil)
                    }
            }
        }
    }

    func fetchLinkAnalytic(for link: String, completion: @escaping (Bool, Bool, LinkAnalytics?) -> Void) {
        let currentUser = Auth.auth().currentUser
        currentUser?.getIDTokenForcingRefresh(true) { idToken, error in
            if let error = error {
                print("Cannot get token: ", error )
                return
            }

            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(idToken ?? "")"
            ]

            AF.request("http://35.222.149.45:8080/analytics/" + link, method: .get, headers: headers)
                .validate(statusCode: 200..<300)
                .responseJSON { response in
//                    debugPrint(response)
                    switch response.result {
                    case .success(let value):
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

                        let json = JSON(value)
                        let id = link
                        let lastAccessDate = dateFormatter.date(from: json["lastAccessDate"].rawString()!)
                        let dailyAverage = json["dailyAverage"].doubleValue
                        let max = json["max"].int64Value
                        let min = json["min"].int64Value
                        let totalPerYear = json["totalPerYear"].int64Value
                        let perMonthClicks =  json["perMonth"].dictionaryObject as? [String: Int64]
                        let browserCounts = json["byBrowsers"].dictionaryObject as? [String: Int64]
                        let osCounts = json["byOs"].dictionaryObject as? [String: Int64]

                        let analytics = LinkAnalytics(id: id, lastAccessDate: lastAccessDate, dailyAverage: dailyAverage, max: max, min: min, totalPerYear: totalPerYear, perMonthClicks: perMonthClicks!, browserCounts: browserCounts!, osCounts: osCounts!)
                        completion(true, true, analytics)
                    case .failure(let error):
                        print(error)
                        self.controller?.showAlert(withTitle: "Fetch Failed", message: error.localizedDescription, option1: "OK", option2: nil)
                        completion(true, false, nil)
                    }
            }
        }
    }
}
