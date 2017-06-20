//
//  SideBarViewController.swift
//  notGIF
//
//  Created by ooatuoo on 2017/6/1.
//  Copyright © 2017年 xyz. All rights reserved.
//

import UIKit
import RealmSwift
import IQKeyboardManagerSwift

class SideBarViewController: UIViewController {
    
    fileprivate var tagResult: Results<Tag>!
    fileprivate var notifiToken: NotificationToken?
    fileprivate var selectTag: Tag!
    
    fileprivate var isEditingTag: Bool {
        return IQKeyboardManager.sharedManager().keyboardShowing
    }

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.tableFooterView = UIView()
            tableView.rowHeight = TagListCell.height
        }
    }
    
    @IBOutlet weak var addTagTextField: CustomTextField! {
        didSet {
            addTagTextField.addTagHandler = { name in
                self.addTag(with: name)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let realm = try? Realm() else { return }
        
        if let tag = realm.object(ofType: Tag.self, forPrimaryKey: NGUserDefaults.lastSelectTagID) {
            selectTag = tag
        } else {
            selectTag = realm.object(ofType: Tag.self, forPrimaryKey: Config.defaultTagID)
            NGUserDefaults.lastSelectTagID = Config.defaultTagID
        }
        
        tagResult = realm.objects(Tag.self).sorted(byKeyPath: "createDate", ascending: false)
        notifiToken = tagResult.addNotificationBlock { [weak self] changes in
            guard let tableView = self?.tableView else { return }
            
            switch changes {
            case .initial:
                tableView.reloadData()
                
            case .update(_, let deletions, let insertions, let modifications):
                tableView.beginUpdates()
                tableView.insertRows(at: insertions.map{ IndexPath(row: $0, section: 0) }, with: .bottom)
                tableView.deleteRows(at: deletions.map{ IndexPath(row: $0, section: 0) }, with: .left)
                tableView.reloadRows(at: modifications.map{ IndexPath(row: $0, section: 0) }, with: .fade)
                tableView.endUpdates()
                
            case .error(let err):
                printLog(err.localizedDescription)
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
        return tagResult == nil ? 0 : tagResult.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TagListCell = tableView.dequeueReusableCell()
        let tag = tagResult[indexPath.item]
        cell.configure(with: tag, isSelected: selectTag.isInvalidated ? false : tag.id == selectTag.id)

        cell.editDoneHandler = { [weak self] text in
            guard let realm = try? Realm(), let sSelf = self,
                let editIP = tableView.indexPath(for: cell) else { return }
            
            try? realm.write {
                realm.add(sSelf.tagResult[editIP.item].update(with: text), update: true)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        guard !isEditingTag else { return }
        
        selectTag = tagResult[indexPath.item]
        tableView.reloadData()
        
        (parent as? DrawerViewController)?.dismissSideBar()
        NotificationCenter.default.post(name: .didSelectTag, object: selectTag)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let actionSize = CGSize(width: 40, height: TagListCell.height)
        let editRowAction = UITableViewRowAction(size: actionSize, image: #imageLiteral(resourceName: "icon_tag_edit"), bgColor: .editYellow) { [weak self] (_, rowActionIP) in
            
            self?.beginEditTag(at: rowActionIP)
        }
        
        let deleteRowAction = UITableViewRowAction(size: actionSize, image: #imageLiteral(resourceName: "icon_tag_delete"), bgColor: .deleteRed) { [weak self] (_, rowActionIP) in
            guard let sSelf = self else { return }
            Alert.show(.confirmDeleteTag(sSelf.tagResult[indexPath.item].name)) {
                self?.deleteTag(at: rowActionIP)
            }
        }
        
        return [editRowAction, deleteRowAction]
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !isEditingTag && tagResult[indexPath.item].id != Config.defaultTagID
    }
}

// MARK: - Helper Method

extension SideBarViewController {
    
    fileprivate func beginEditTag(at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? TagListCell else { return }
        tableView.setEditing(false, animated: true)
        cell.beginEdit()
    }
    
    fileprivate func deleteTag(at indexPath: IndexPath) {
        guard let realm = try? Realm() else { return }
        
        let tag = tagResult[indexPath.item]
        if tag.id == selectTag.id { // 若删除当前选中 Tag，则将 gif 列表更新至默认标签
            selectTag = tagResult[0]
            tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
            NotificationCenter.default.post(name: .didSelectTag, object: selectTag)
        }
        
        try? realm.write {
            realm.delete(tag)
        }
    }
    
    fileprivate func addTag(with name: String) {
        guard let realm = try? Realm() else { return }

        tableView.setEditing(false, animated: true)
        tableView.setContentOffset(.zero, animated: true)

        DispatchQueue.main.after(0.5) {
            try? realm.write {
                realm.add(Tag(name: name))
            }
        }
    }
}
