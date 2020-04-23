//
//  LinksController+Updating.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/23/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import UIKit

// swiftlint:disable force_cast
extension LinksController: UISearchResultsUpdating, SelectedCellProtocol {
    func didSelectedLink(_ link: Link) {
        let detailViewController = self.storyboard?.instantiateViewController(withIdentifier: "LinkDetailsNavigationController") as! UINavigationController
        let linkDetailsController = detailViewController.viewControllers.first as! LinkDetailsController
        linkDetailsController.viewModel = viewModel
        linkDetailsController.link = link
        self.splitViewController?.showDetailViewController(detailViewController, sender: self)
    }

    func updateSearchResults(for searchController: UISearchController) {
        // Update the filtered array based on the search text.
        let searchResults = sections

        // Strip out all the leading and trailing spaces.
        let whitespaceCharacterSet = CharacterSet.whitespaces
        let strippedString = searchController.searchBar.text!.trimmingCharacters(in: whitespaceCharacterSet)

        var filteredResults = [Link]()
        for index in 0..<sections.count {
            filteredResults.append(contentsOf: searchResults[index].filter {
                $0.title.contains(strippedString) ||
                $0.shortURL.contains(strippedString)
            })
        }

        // Apply the filtered results to the search results table.
        if let resultsController = searchController.searchResultsController as? ResultsTableController {
            resultsController.viewModel = viewModel
            resultsController.matchedString = strippedString
            resultsController.filteredLinks = filteredResults
            resultsController.tableView.reloadData()
        }
    }

}
