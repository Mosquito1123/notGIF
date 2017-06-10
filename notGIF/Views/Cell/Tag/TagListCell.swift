//
//  TagListCell.swift
//  notGIF
//
//  Created by Atuooo on 03/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

class TagListCell: UITableViewCell {
    
    public var editDoneHandler: ((String) -> ())?
    public var editCancelHandler: (() -> ())?
    public var endEditHandler: (() -> ())?
    
    @IBOutlet weak var nameField: CustomTextField!
    @IBOutlet weak var countLabel: UILabel!
    
    fileprivate var tagName: String = ""
    
    fileprivate lazy var doneButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        button.setTitle("完成", for: .normal)
        button.setTitleColor(UIColor.textTint, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.addTarget(self, action: #selector(TagListCell.doneButtonClicked), for: .touchUpInside)
        return button
    }()
    
    fileprivate lazy var cancelButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        button.setTitle("取消", for: .normal)
        button.setTitleColor(UIColor.textTint, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.addTarget(self, action: #selector(TagListCell.cancelButtonClicked), for: .touchUpInside)
        return button
    }()
    
    fileprivate lazy var toolBar: UIToolbar = {
        var bar = UIToolbar(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: 40))
        bar.backgroundColor = .black
        let doneItem = UIBarButtonItem(customView: self.doneButton)
        let cancelItem = UIBarButtonItem(customView: self.cancelButton)
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        bar.items = [space, cancelItem, space, doneItem, space]
        return bar
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        nameField.inputAccessoryView = toolBar
        nameField.text = nil
        countLabel.text = nil
        
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        nameField.isEnabled = false
        nameField.text = nil
        countLabel.text = nil
    }
    
    public func configure(with tag: Tag) {
//        let isSelect = tag.id == NGUserDefaults.lastSelectTagID
//        nameField.font = isSelect ? UIFont.systemFont(ofSize: 30, weight: 24) : UIFont.systemFont(ofSize: 18)
//        nameField.textColor = isSelect ? .red : .white
        tagName = tag.name
        nameField.text = tagName
        countLabel.text = "\(tag.gifs.count)"
    }
    
    public func beginEdit() {
        nameField.isEnabled = true
        nameField.becomeFirstResponder()
    }
}

// MARK: - ToolBar Handler 

extension TagListCell {
    
    func doneButtonClicked() {
        tagName = nameField.text ?? ""
        editDoneHandler?(tagName)
        nameField.resignFirstResponder()
    }
    
    func cancelButtonClicked() {
        nameField.text = tagName
        editCancelHandler?()
        nameField.resignFirstResponder()
    }
}

// MARK: - TextField Delegate

extension TagListCell: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        doneButtonClicked()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        nameField.isEnabled = false
        endEditHandler?()
    }
}
