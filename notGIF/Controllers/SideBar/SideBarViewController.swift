//
//  SideBarViewController.swift
//  notGIF
//
//  Created by ooatuoo on 2017/6/1.
//  Copyright © 2017年 xyz. All rights reserved.
//

import UIKit
import RealmSwift

fileprivate let cellID = "TagListCell"

class SideBarViewController: UIViewController {
    
    fileprivate var selectedTag: Tag!
    
    fileprivate var tagResult: Results<Tag>!
    fileprivate var notifiToken: NotificationToken?
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.tableFooterView = UIView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let realm = try? Realm() else { return }
        
        tagResult = realm.objects(Tag.self).sorted(byKeyPath: "createDate", ascending: false)
        
        notifiToken = tagResult.addNotificationBlock { [weak self] changes in
            guard let tableView = self?.tableView else { return }
            
            switch changes {
                
            case .initial:
                tableView.reloadData()
                
            case .update(_, let deletions, let insertions, let modifications):
                tableView.beginUpdates()
                tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
                                     with: .fade)
                tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}),
                                     with: .fade)
                tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
                                     with: .fade)
                tableView.endUpdates()
                
            case .error(let err):
                print(err.localizedDescription)
            }
        }
    }
    
    deinit {
        notifiToken?.stop()
        notifiToken = nil
    }
}

extension SideBarViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tagResult != nil ? tagResult.count : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID) as! TagListCell
        
        let tag = tagResult[indexPath.item]
        cell.tagNameLabel.text = tag.name
        cell.countLabel.text = "\(tag.gifs.count)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}
