//
//  RecentAndFilterViewController.swift
//  OneDay
//
//  Created by juhee on 20/02/2019.
//  Copyright © 2019 teamA2. All rights reserved.
//

import UIKit
import CoreData

class RecentAndFilterViewController: UIViewController {

    @IBOutlet weak var recentFilterTable: UITableView!
    
    weak var delegator: FilterViewControllerDelegate?
    
    private var entries: [Entry]!
    private var recentKeywords: [(keyword: String, entries: [Entry])] = []
    private var filtersArray: [(type: FilterTableCellType, data: [NSManagedObject])] = {
        var array: [(type: FilterTableCellType, data: [NSManagedObject])] = []
        FilterTableCellType.allCases.forEach { cellType in
            array.append((type: cellType, data: cellType.data))
        }
        return array
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recentFilterTable.register(FilterCell.self, forCellReuseIdentifier: Section.filter.identifier)
        recentFilterTable.register(SearchedKeywordCell.self, forCellReuseIdentifier: Section.recent.identifier)
        addRecentKeywordsChangedNotificationObserver()
        loadRecentKeywordsData()
    }
    
    func bind(entries: [Entry], delegator: FilterViewControllerDelegate) {
        self.entries = entries
        self.delegator = delegator
    }
    
    private func addRecentKeywordsChangedNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveRecentKeywordsChangedNotification(_:)),
            name: OneDayDefaults.DidChangedRecentKeywordsNotification,
            object: nil)
    }
    
    @objc func didReceiveRecentKeywordsChangedNotification(_: Notification) {
        loadRecentKeywordsData()
    }
    
    func loadRecentKeywordsData() {
        var array = [(String, [Entry])]()
        let originKeywords = OneDayDefaults.currentKeywords
        let maximumCount: Int = min(Constants.minimumRecentKeywordsCount, originKeywords.count)
        var keywords = OneDayDefaults.currentKeywords.reversed()[0..<maximumCount]
        for index in 0..<maximumCount {
            let keyword = keywords[index]
            array.append((keyword, entries.filter { $0.contents?.string.contains(keyword) ?? false }))
        }
        recentKeywords = array
        recentFilterTable.reloadData()
    }
    
}
extension RecentAndFilterViewController {
    
    enum Section: Int {
        case recent = 0
        case filter = 1
        
        var sectionNumber: Int {
            return self.rawValue
        }
        
        var sectionTitle: String {
            switch self {
            case .recent: return "최근"
            case .filter: return "필터"
            }
        }
        
        var identifier: String {
            switch self {
            case .recent: return "recent_cell"
            case .filter: return "filter_cell"
            }
        }
        
        var heightForSection: CGFloat {
            return 50
        }
    }
}

extension RecentAndFilterViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionType = Section(rawValue: section) else { preconditionFailure() }
        return sectionType.sectionTitle
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { preconditionFailure() }
        if sectionType == .recent {
            return recentKeywords.count
        } else {
            return filtersArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = Section(rawValue: indexPath.section) else { preconditionFailure() }

        switch sectionType {
        case .recent:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: sectionType.identifier, for: indexPath) as? SearchedKeywordCell else { preconditionFailure("Cell Error") }
            let recentKeyword = recentKeywords[indexPath.row]
            cell.bind(keyword: recentKeyword.keyword, count: recentKeyword.entries.count)
            return cell
        case .filter:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: sectionType.identifier,
                                                           for: indexPath) as? FilterCell
                else { preconditionFailure("Cell Error") }
            let filterData = filtersArray[indexPath.row]
            cell.bind(filter: filterData.type, count: filterData.data.count)
            return cell
        }
    }
    
}

extension RecentAndFilterViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let sectionType = Section(rawValue: indexPath.section) else { preconditionFailure() }
        switch sectionType {
        case .recent:
            let recentKeyword = recentKeywords[indexPath.row]
            if !recentKeyword.entries.isEmpty {
                delegator?.presentCollectedEntries(for: recentKeyword.entries, title: recentKeyword.keyword)
            }
        case .filter:
            let filterData = filtersArray[indexPath.row]
            if filterData.type.isOneDepth {
                guard let entries = filterData.data as? [Entry] else { preconditionFailure() }
                delegator?.presentCollectedEntries(for: entries, title: filterData.type.title)
            } else {
                
            }
        }
    }
}

protocol FilterViewControllerDelegate: class {
    func presentCollectedEntries(for: [Entry], title: String)
}