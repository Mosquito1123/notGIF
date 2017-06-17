//
//  AddTagListViewController.swift
//  notGIF
//
//  Created by Atuooo on 17/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit
import RealmSwift

private let width = kScreenWidth * 0.8

class AddTagListViewController: UIViewController {

    fileprivate var tagResult: Results<Tag>!
    fileprivate var notifiToken: NotificationToken?
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.tableFooterView = UIView()
            tableView.tableHeaderView = addTagHeader
        }
    }
    
    fileprivate lazy var addTagHeader: AddTagTextfieldHeader = {
        return AddTagTextfieldHeader(width: width, addTagHandler: { name in
            self.addTag(with: name)
        })
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        preferredContentSize = CGSize(width: width, height: kScreenHeight * 0.6)
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
                
            case .update(_, _, let insertions, _):
                tableView.beginUpdates()
                tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }), with: .bottom)
                tableView.endUpdates()
                
            case .error(let err):
                printLog(err.localizedDescription)
            }
        }
    }

    @IBAction func cancelItemClicked(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func addItemClicked(_ sender: UIBarButtonItem) {
        
    }
    
    fileprivate func addTag(with name: String) {
        guard let realm = try? Realm() else { return }
        
        let newTag = Tag(name: name)
        try? realm.write {
            realm.add(newTag)
        }
    }
}

extension AddTagListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  tagResult == nil ? 0 : tagResult.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: AddTagListCell = tableView.dequeueReusableCell()
        cell.configure(with: tagResult[indexPath.item])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard tagResult[indexPath.item].id != Config.defaultTagID else { return }
        
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .none        
    }
}
