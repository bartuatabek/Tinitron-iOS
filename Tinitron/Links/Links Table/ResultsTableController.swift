//
//  ResultsTableController.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/19/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import UIKit

protocol SelectedCellProtocol: AnyObject {
    func didSelectedLink(_ link: Link)
}

class ResultsTableController: UITableViewController {

    /// Data models for the table view.
    var viewModel: LinksViewModeling?
    var filteredLinks = [Link]()
    var matchedString = ""

    weak var delegate: SelectedCellProtocol?

    fileprivate func generateAttributedString(with searchTerm: String, targetString: String, color: UIColor) -> NSAttributedString? {
        let attributedString = NSMutableAttributedString(string: targetString)
        do {
            let regex = try NSRegularExpression(pattern: searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: .diacriticInsensitive, locale: .current), options: .caseInsensitive)
            let range = NSRange(location: 0, length: targetString.utf16.count)
            for match in regex.matches(in: targetString.folding(options: .diacriticInsensitive, locale: .current), options: .withTransparentBounds, range: range) {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: match.range)
            }
            return attributedString
        } catch {
            NSLog("Error creating regular expresion: \(error)")
            return nil
        }
    }

    // MARK: - UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        if filteredLinks.isEmpty {
            tableView.setEmptyMessage("No Search Results")
        } else {
            tableView.restore()
        }

        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredLinks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchLinkCell", for: indexPath) //SuggestedSearchCell

        cell.textLabel?.textColor = UIColor.label.withAlphaComponent(0.5)
        cell.textLabel?.attributedText = generateAttributedString(with: matchedString, targetString: filteredLinks[indexPath.row].title, color: UIColor.label)

        if filteredLinks[indexPath.row].expirationDate < Date() {
            cell.detailTextLabel?.textColor = UIColor.systemPink.withAlphaComponent(0.5)
            cell.detailTextLabel?.attributedText = generateAttributedString(with: matchedString, targetString: filteredLinks[indexPath.row].shortURL, color: UIColor.systemPink)
            cell.imageView?.tintColor = .systemPink
        } else {
            cell.detailTextLabel?.textColor = UIColor.link.withAlphaComponent(0.5)
            cell.detailTextLabel?.attributedText = generateAttributedString(with: matchedString, targetString: filteredLinks[indexPath.row].shortURL, color: UIColor.link)
            cell.imageView?.tintColor = .systemBlue
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.didSelectedLink(filteredLinks[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
