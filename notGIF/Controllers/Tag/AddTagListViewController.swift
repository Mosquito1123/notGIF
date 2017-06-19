//
//  AddTagListViewController.swift
//  notGIF
//
//  Created by Atuooo on 17/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit
import RealmSwift
import IQKeyboardManagerSwift

private let width = kScreenWidth * 0.8

class AddTagListViewController: UIViewController {

    public var toAddGIFs: [NotGIF] = []
    public var fromTag: Tag!
    
    public var addGIFTagCompletion: CommonCompletion?
    
    fileprivate var tagResult: Results<Tag>!
    fileprivate var notifiToken: NotificationToken?
    
    fileprivate var selectedTags: [Tag] = [] {
        didSet {
            addItem.isEnabled = !selectedTags.isEmpty
            navigationItem.title = String.trans_titleChoosedTag(selectedTags.count)
        }
    }
    
    @IBOutlet weak var cancelItem: UIBarButtonItem!
    @IBOutlet weak var addItem: UIBarButtonItem!
    
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
    
    // MARK: - Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        preferredContentSize = CGSize(width: width, height: kScreenHeight * 0.6)
        cancelItem.title = String.trans_titleCancel
        addItem.title = String.trans_titleAdd
        
        cancelItem.setTitleTextAttributes([NSFontAttributeName: UIFont.menlo(ofSize: 16)], for: .normal)
        addItem.setTitleTextAttributes([NSFontAttributeName: UIFont.menlo(ofSize: 16)], for: .normal)
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        notifiToken?.stop()
        notifiToken = nil
    }
    
    deinit {
        // TODO: - not call
        printLog("deinited")
    }
    
    // MARK: - Item Handler

    @IBAction func cancelItemClicked(_ sender: UIBarButtonItem) {
        addTagHeader.editCancel()
        dismiss(animated: true, completion: nil)
    }

    @IBAction func addItemClicked(_ sender: UIBarButtonItem) {
        guard !IQKeyboardManager.sharedManager().keyboardShowing, !selectedTags.isEmpty else { return }
                
        try? Realm().write {
            selectedTags.forEach {
                $0.gifs.add(objectsIn: toAddGIFs, update: true)
            }
        }
        
        // TODO: - HUD
        dismiss(animated: true) {
            self.addGIFTagCompletion?()
        }
    }
    
    fileprivate func addTag(with name: String) {
        guard let realm = try? Realm() else { return }
        
        let newTag = Tag(name: name)
        try? realm.write {
            realm.add(newTag)
        }
    }
}

// MARK: - TableView Delegate

extension AddTagListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  tagResult == nil ? 0 : tagResult.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: AddTagListCell = tableView.dequeueReusableCell()
        let tag = tagResult[indexPath.item]
        cell.configure(with: tag, isChoosed: selectedTags.contains(tag))
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        guard indexPath.item > 0 else { return }    // default Tag 禁止移除
        
        let cell = tableView.cellForRow(at: indexPath)
        let tag = tagResult[indexPath.item]
        
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
            cell?.accessoryType = .none
        } else {
            selectedTags.append(tag)
            cell?.accessoryType = .checkmark
        }
    }
}
