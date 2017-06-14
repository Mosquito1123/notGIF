//
//  SideBarViewController.swift
//  notGIF
//
//  Created by ooatuoo on 2017/6/1.
//  Copyright © 2017年 xyz. All rights reserved.
//

import UIKit
import RealmSwift

// 添加 Tag 时插入的位置
private let newTagCellInsertIP = IndexPath(item: 1, section: 0)

class SideBarViewController: UIViewController {
    
    fileprivate var isEditingTag: Bool = false {
        didSet {    // 编辑时禁止返回
            guard let drawer = parent as? DrawerViewController else { return }
            drawer.mainContainer.isUserInteractionEnabled = !isEditingTag
        }
    }
    
    fileprivate var tagList: [Tag] = []
    fileprivate var tagResult: Results<Tag>!
    fileprivate var notifiToken: NotificationToken?
    fileprivate var selectTag: Tag!
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.tableFooterView = UIView()
            tableView.rowHeight = TagListCell.height
        }
    }
    
    @IBOutlet weak var addTagButton: UIButton! {
        didSet {
            addTagButton.setTitle(String.trans_tag, for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let realm = try? Realm() else { return }
        
        selectTag = realm.object(ofType: Tag.self, forPrimaryKey: NGUserDefaults.lastSelectTagID)
        tagResult = realm.objects(Tag.self).sorted(byKeyPath: "createDate", ascending: false)
        tagList.append(contentsOf: tagResult)
        
        notifiToken = tagResult.addNotificationBlock { [weak self] changes in
            guard let tableView = self?.tableView else { return }
            
            switch changes {
            case .initial:
                tableView.reloadData()
                
            case .update(_, let deletions, let insertions, let modifications):
                tableView.beginUpdates()
//                tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }), with: .fade)
                tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }), with: .fade)
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
    
    @IBAction func addTagButtonClicked(_ sender: UIButton) {
        guard !isEditingTag, tagList.count > 0 else { return }
        
        UIView.animate(withDuration: 0.2, animations: { 
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            self.tableView.setEditing(false, animated: false)

        }) { _ in
            
            self.isEditingTag = true
            self.tagList.insert(Tag(name: ""), at: newTagCellInsertIP.item)
            self.tableView.insertRows(at: [newTagCellInsertIP], with: .top)
            self.beginEditTag(at: newTagCellInsertIP)
        }
    }
}

extension SideBarViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tagList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TagListCell = tableView.dequeueReusableCell()
        let tag = tagList[indexPath.item]
        cell.configure(with: tag, isSelected: tag.id == selectTag.id)

        cell.editDoneHandler = { [unowned self] text in
            guard let realm = try? Realm(),
                let editIP = tableView.indexPath(for: cell) else { return }
            
            try? realm.write {
                realm.add(self.tagList[editIP.item].update(with: text), update: true)
            }
        }
        
        cell.editCancelHandler = { [unowned self] in
            let tag = self.tagList[indexPath.item]
            if !self.tagResult.contains(tag) {  // 新建的 Tag
                self.tagList.remove(at: indexPath.item)
                tableView.deleteRows(at: [indexPath], with: .bottom)
            }
        }
        
        cell.endEditHandler = { [unowned self] in
            self.isEditingTag = false
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        let tag = tagList[indexPath.item]
        guard !isEditingTag, tag.id != selectTag.id else {
            return
        }
        
        selectTag = tag
        tableView.reloadData()
        
        (parent as? DrawerViewController)?.dismissSideBar()
        NotificationCenter.default.post(name: .didSelectTag, object: tag)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let actionSize = CGSize(width: 40, height: TagListCell.height)
        let editRowAction = UITableViewRowAction(size: actionSize, image: #imageLiteral(resourceName: "icon_tag_edit"), bgColor: .editYellow) { [unowned self] (_, rowActionIP) in
            
            self.beginEditTag(at: rowActionIP)
        }
        
        let deleteRowAction = UITableViewRowAction(size: actionSize, image: #imageLiteral(resourceName: "icon_tag_delete"), bgColor: .deleteRed) { [unowned self] (_, rowActionIP) in
            
            self.tableView.setEditing(false, animated: true)
            Alert.show(.confirmDeleteTag) {
                self.deleteTag(at: rowActionIP)
            }
        }
        
        return [editRowAction, deleteRowAction]
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !isEditingTag && tagList[indexPath.item].id != Config.defaultTagID
    }
}

extension SideBarViewController {
    
    fileprivate func beginEditTag(at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? TagListCell else { return }
        isEditingTag = true
        tableView.setEditing(false, animated: true)
        cell.beginEdit()
    }
    
    fileprivate func deleteTag(at indexPath: IndexPath) {
        guard let realm = try? Realm() else { return }
        try? realm.write {
            realm.delete(tagList[indexPath.item])
        }
        
        tagList.remove(at: indexPath.item)
        tableView.deleteRows(at: [indexPath], with: .left)
    }
}
