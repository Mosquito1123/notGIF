//
//  TagListCell.swift
//  notGIF
//
//  Created by Atuooo on 03/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

class TagListCell: UITableViewCell {
    
    static let height: CGFloat = 52
    
    public var editDoneHandler: ((String) -> ())?
    public var editCancelHandler: (() -> ())?
    public var endEditHandler: (() -> ())?
    
    @IBOutlet weak var nameField: CustomTextField!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var leftMark: UIImageView!
    @IBOutlet weak var rightMark: UIImageView!
    
    fileprivate var tagName: String = ""
    
    fileprivate lazy var doneButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 40))
        button.setTitle(String.trans_titleDone, for: .normal)
        button.setTitleColor(UIColor.darkText, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.addTarget(self, action: #selector(TagListCell.doneButtonClicked), for: .touchUpInside)
        return button
    }()
    
    fileprivate lazy var cancelButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 40))
        button.setTitle(String.trans_titleCancel, for: .normal)
        button.setTitleColor(UIColor.darkText, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.addTarget(self, action: #selector(TagListCell.cancelButtonClicked), for: .touchUpInside)
        return button
    }()
    
    fileprivate lazy var toolBar: UIToolbar = {
        var bar = UIToolbar(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: 40))
        bar.backgroundColor = UIColor.lightGray
        let doneItem = UIBarButtonItem(customView: self.doneButton)
        let cancelItem = UIBarButtonItem(customView: self.cancelButton)
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        bar.items = [space, cancelItem, space, space, doneItem, space]
        return bar
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        nameField.inputAccessoryView = toolBar
        nameField.text = nil
        countLabel.text = nil
        
        nameField.font = UIFont.menlo(ofSize: 17)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        nameField.isEnabled = false
        nameField.text = nil
        countLabel.text = nil
    }
    
    public func configure(with tag: Tag, isSelected: Bool) {
        if isSelected {
            nameField.textColor = UIColor.textTint
            nameField.font = UIFont.menlo(ofSize: 19)
        } else {
            nameField.textColor = UIColor.textTint.withAlphaComponent(0.77)
            nameField.font = UIFont.menlo(ofSize: 17)
        }
        
        tagName = tag.localNameStr
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
