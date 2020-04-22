//
//  LinksController.swift
//  Tinitron
//
//  Created by Bartu Atabek on 4/11/20.
//  Copyright © 2020 Bartu Atabek. All rights reserved.
//

import UIKit
import SkeletonView

class LinksController: UITableViewController {

    let formatter = DateFormatter()

    var filter = false
    var selectedLink: Link?

    /// Data models for the table view.
    var viewModel: LinksViewModeling?

    var sections = [[Link]]()
    var unfilteredSections = [[Link]]()

    /// Search controller to help us with filtering items in the table view.
    var searchController: UISearchController!

    private var resultsTableController: ResultsTableController!

    /// Restoration state for UISearchController
    var restoredState = SearchControllerRestorableState()

    // MARK: - ViewController Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel = LinksViewModel()
        self.viewModel?.controller = self

        formatter.dateFormat = "MMM d, yyyy"
        sections = getSectionsBasedOnDate(links: viewModel!.links)
        sections.insert([Link](), at: 0)

        self.navigationItem.leftBarButtonItem = self.editButtonItem
        tableView.allowsMultipleSelectionDuringEditing = true

        resultsTableController =
        self.storyboard?.instantiateViewController(withIdentifier: "ResultsTableController") as? ResultsTableController

        searchController = UISearchController(searchResultsController: resultsTableController)
//        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.delegate = self // Monitor when the search button is tapped.
        self.navigationItem.searchController = searchController
        definesPresentationContext = true

        let expire = UIBarButtonItem(title: "Expire", style: .plain, target: self, action: #selector(expireSelectedItems))
        let delete = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(deleteSelectedItems))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        toolbarItems = [expire, spacer, delete]

        // swiftlint:disable force_cast
        let splitViewController = tabBarController?.viewControllers![1] as! UISplitViewController
        let navigationController = splitViewController.masterViewController as! UINavigationController
        let analyticsContoller = navigationController.topViewController as! AnalyticsController
        analyticsContoller.viewModel = viewModel
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Restore the searchController's active state.
        if restoredState.wasActive {
            searchController.isActive = restoredState.wasActive
            restoredState.wasActive = false

            if restoredState.wasFirstResponder {
                searchController.searchBar.becomeFirstResponder()
                restoredState.wasFirstResponder = false
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // swiftlint:disable force_cast
        let splitViewController = tabBarController?.viewControllers![1] as! UISplitViewController
        let navigationController = splitViewController.masterViewController as! UINavigationController
        let analyticsContoller = navigationController.topViewController as! AnalyticsController
        analyticsContoller.viewModel = viewModel
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

    fileprivate func unpinItem(link: Link) -> Int {
        var success = false
        var sectionIndex = 0

        for index in 1..<sections.count {
            if Calendar.current.isDate(sections[index].first!.creationDate, inSameDayAs: link.creationDate) {
                sections[index].append(link)
                sectionIndex = index
                success = true
            }
        }

        if !success {
            sections.append([Link](arrayLiteral: link))
            sectionIndex = sections.count - 1
        }
        return sectionIndex
    }

    // MARK: - Button actions
    @IBAction func filter(_ sender: Any) {
        filter.toggle()
        self.navigationItem.rightBarButtonItems?[1].image = filter ? UIImage(systemName: "line.horizontal.3.decrease.circle.fill") : UIImage(systemName: "line.horizontal.3.decrease.circle")

        if filter {
            var expiredLinks = [Link]()

            unfilteredSections = sections
            for index in 0..<sections.count {
                expiredLinks.append(contentsOf: sections[index].filter { $0.isExpired })
                sections[index] = sections[index].filter { !$0.isExpired }
            }

            sections.insert(expiredLinks, at: 0)
        } else {
            sections = unfilteredSections
            unfilteredSections.removeAll()
        }
        tableView.reloadData()
    }

    @objc fileprivate func expireSelectedItems() {
        var expireKeys = [String]()

        if let selectedRows = tableView.indexPathsForSelectedRows {
            for row in selectedRows {
                self.sections[row.section][row.row].expirationDate = Date()
                expireKeys.append(self.sections[row.section][row.row].shortURL)
            }

            self.viewModel?.expireLinks(links: expireKeys, completion: { (finished, success) in
                if finished && success {
                    for index in 0..<expireKeys.count {
                        if let index = self.viewModel?.links.firstIndex(where: {$0.shortURL == expireKeys[index]}) {
                            self.viewModel?.links[index].expirationDate = Date()
                        }
                    }
                }
            })

            tableView.beginUpdates()
            tableView.reloadRows(at: selectedRows, with: .automatic)
            tableView.endUpdates()
        }
    }

    @objc fileprivate func deleteSelectedItems() {
        var deleteKeys = [String]()

        if let selectedRows = tableView.indexPathsForSelectedRows {
            for row in selectedRows {
                deleteKeys.append(self.sections[row.section][row.row].shortURL)
                self.sections[row.section].remove(at: row.row)
            }

            self.viewModel?.deleteLinks(links: deleteKeys, completion: { (finished, success) in
                if finished && success {
                    for index in 0..<deleteKeys.count {
                        if let index = self.viewModel?.links.firstIndex(where: {$0.shortURL == deleteKeys[index]}) {
                            self.viewModel?.links.remove(at: index)
                        }
                    }
                }
            })

            tableView.beginUpdates()
            tableView.deleteRows(at: selectedRows, with: .automatic)
            tableView.endUpdates()
        }
    }

    // MARK: Refresh Control
    @IBAction func refresh(_ sender: UIRefreshControl) {
        view.showAnimatedSkeleton()
        viewModel?.fetchLinks(completion: { (finished, success, fetchedLinks) in
            if finished && success {
                self.viewModel?.links = fetchedLinks!
                self.sections = self.getSectionsBasedOnDate(links: fetchedLinks!)
            }

            if finished {
                sender.endRefreshing()
                self.tableView.reloadData()
                self.view.hideSkeleton(transition: .crossDissolve(0.25))
            }
        })
    }

    // MARK: - Navigation
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return !self.isEditing
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToCreateLink" {
            let navigationController = segue.destination as? UINavigationController
            let createLinkController = navigationController!.viewControllers.first as? CreateLinkController
            createLinkController?.viewModel = viewModel
        }
    }
}

// MARK: - UITableViewDelegate
extension LinksController {
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if filter && section == 0 {
            return "Expired Links"
        } else if (filter && section == 1) || (!filter && section == 0) {
            if self.tableView(tableView, numberOfRowsInSection: section) > 0 {
                return "Pinned Links"
            } else {
                return nil
            }
        }

        if let item = sections[section].first, self.tableView(tableView, numberOfRowsInSection: section) > 0 {
            return formatter.string(from: item.creationDate)
        } else {
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing { return }

        selectedLink = sections[indexPath.section][indexPath.row]
        let detailViewController = self.storyboard?.instantiateViewController(withIdentifier: "LinkDetailsNavigationController") as! UINavigationController
        let linkDetailsController = detailViewController.viewControllers.first as! LinkDetailsController
        linkDetailsController.viewModel = viewModel
        linkDetailsController.link = selectedLink
        self.splitViewController?.showDetailViewController(detailViewController, sender: self)

        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var pin: UIContextualAction
        if indexPath.section == (self.filter ? 1 : 0) {
            // Unpin
            pin = UIContextualAction(style: .normal, title: "Unpin") { (_, _, completionHandler) in
                print("index path of edit: \(indexPath)")
                let sectionIndex = self.unpinItem(link: self.sections[indexPath.section].remove(at: indexPath.row))
                tableView.reloadSections(IndexSet(arrayLiteral: self.filter ? 1 : 0, sectionIndex), with: .automatic)
                completionHandler(true)
            }
            pin.backgroundColor = .systemTeal
            pin.image = UIImage(systemName: "pin.slash")
        } else {
            // Pin
            pin = UIContextualAction(style: .normal, title: "Pin") { (_, _, completionHandler) in
                print("index path of edit: \(indexPath)")
                self.sections[self.filter ? 1 : 0].append(self.sections[indexPath.section].remove(at: indexPath.row))
                tableView.reloadSections(IndexSet(arrayLiteral: self.filter ? 1 : 0, indexPath.section), with: .fade)
                completionHandler(true)
            }
            pin.backgroundColor = .systemTeal
            pin.image = UIImage(systemName: "pin")
        }

        if self.sections[indexPath.section][indexPath.row].isExpired {
            let swipeActionConfig = UISwipeActionsConfiguration(actions: [pin])
            return swipeActionConfig
        }

        let copyLink = UIContextualAction(style: .normal, title: "Copy Link") { (_, _, completionHandler) in
            print("index path of edit: \(indexPath)")
            UIPasteboard.general.string = self.sections[indexPath.section][indexPath.row].shortURL
            completionHandler(true)
        }
        copyLink.backgroundColor = .darkGray
        copyLink.image = UIImage(systemName: "rectangle.on.rectangle")

        let swipeActionConfig = UISwipeActionsConfiguration(actions: [copyLink, pin])
        return swipeActionConfig
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { (_, _, completionHandler) in
            print("index path of delete: \(indexPath)")

            let deleteKey = self.sections[indexPath.section][indexPath.row].shortURL
            self.viewModel?.deleteLinks(links: [deleteKey], completion: { (finished, success) in
                if finished && success {
                    if let index = self.viewModel?.links.firstIndex(where: {$0.shortURL == deleteKey}) {
                        self.viewModel?.links.remove(at: index)
                    }
                }
            })

            self.sections[indexPath.section].remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completionHandler(true)
        }
        delete.image = UIImage(systemName: "trash.fill")

        if self.sections[indexPath.section][indexPath.row].isExpired {
            let swipeActionConfig = UISwipeActionsConfiguration(actions: [delete])
            return swipeActionConfig
        }

        let expire = UIContextualAction(style: .normal, title: "Expire") { (_, _, completionHandler) in
            print("index path of edit: \(indexPath)")

            let linkKey = self.sections[indexPath.section][indexPath.row].shortURL
            self.viewModel?.expireLinks(links: [linkKey], completion: { (finished, success) in
                if finished && success {
                    if let index = self.viewModel?.links.firstIndex(where: {$0.shortURL == linkKey}) {
                        self.viewModel?.links[index].expirationDate = Date()
                    }
                }
            })

            self.sections[indexPath.section][indexPath.row].expirationDate = Date()
            tableView.reloadRows(at: [indexPath], with: .automatic)
            completionHandler(true)
        }
        expire.backgroundColor = .systemIndigo
        expire.image = UIImage(systemName: "hourglass")

        let share = UIContextualAction(style: .normal, title: "Share") { (_, _, completionHandler) in
            print("index path of edit: \(indexPath)")
            if let url = URL(string: "https://" + self.sections[indexPath.section][indexPath.row].shortURL) {
                let items: [Any] = [url]
                let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)
                activityController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)?.contentView
                self.present(activityController, animated: true)
            }

            completionHandler(true)
        }
        share.backgroundColor = .systemBlue
        share.image = UIImage(systemName: "square.and.arrow.up")

        let swipeActionConfig = UISwipeActionsConfiguration(actions: [delete, expire, share])
        return swipeActionConfig
    }

    // Override to support rearranging the table view.
    // swiftlint:disable identifier_name
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        let rowToMove = sections[fromIndexPath.section][fromIndexPath.row]

        sections[fromIndexPath.section].remove(at: fromIndexPath.row)
        sections[fromIndexPath.section].insert(rowToMove, at: to.row)
    }

    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        let sourceSection = sourceIndexPath.section
        let destSection = proposedDestinationIndexPath.section

        if destSection < sourceSection {
            return IndexPath(row: 0, section: sourceSection)
        } else if destSection > sourceSection {
            return IndexPath(row: self.tableView(tableView, numberOfRowsInSection: sourceSection)-1, section: sourceSection)
        }

        return proposedDestinationIndexPath
    }

    override func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        // Replace the Edit button with Done, and put the table view into editing mode.
        self.setEditing(true, animated: true)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        navigationController?.setToolbarHidden(!editing, animated: true)
        super.setEditing(editing, animated: animated)
    }
}

// MARK: - UITableViewDataSource
extension LinksController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LinkCell", for: indexPath)

        cell.textLabel?.text = sections[indexPath.section][indexPath.row].title
        cell.detailTextLabel?.text = sections[indexPath.section][indexPath.row].shortURL

        if sections[indexPath.section][indexPath.row].expirationDate < Date() {
            cell.detailTextLabel?.textColor = .systemPink
            cell.imageView?.tintColor = .systemPink
        } else {
            cell.detailTextLabel?.textColor = .link
            cell.imageView?.tintColor = .systemBlue
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

// MARK: - UISearchBarDelegate
extension LinksController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - UISearchControllerDelegate
// Use these delegate functions for additional control over the search controller.
extension LinksController: UISearchControllerDelegate {
    func presentSearchController(_ searchController: UISearchController) {
        //Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }

    func willPresentSearchController(_ searchController: UISearchController) {
        //Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }

    func didPresentSearchController(_ searchController: UISearchController) {
        //Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        //Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        //Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
    }
}

// MARK: - SkeletonTableViewDataSource
extension LinksController: SkeletonTableViewDataSource {
    func numSections(in collectionSkeletonView: UITableView) -> Int {
        return 10
    }

    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "LinkCell"
    }
}
