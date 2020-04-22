//
//  ResultsTableController.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/19/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import UIKit

class ResultsTableController: UITableViewController {

    var filteredLinks = [Link]()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

//    // MARK: - UITableViewDataSource
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return filteredLinks.count
//    }
//
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchLinkCell", for: indexPath)
//
//        cell.textLabel?.text = filteredLinks[indexPath.row].title
//        cell.detailTextLabel?.text = filteredLinks[indexPath.row].shortURL
//
//        if filteredLinks[indexPath.row].expirationDate < Date() {
//            cell.detailTextLabel?.textColor = .systemPink
//            cell.imageView?.tintColor = .systemPink
//        } else {
//            cell.detailTextLabel?.textColor = .link
//            cell.imageView?.tintColor = .systemBlue
//        }
//
//        return cell
//    }
}
