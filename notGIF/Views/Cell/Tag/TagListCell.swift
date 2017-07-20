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
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var countLabel: UILabel!
    
    fileprivate var couldEndEdit: Bool = false
    
    fileprivate var tagName: String = ""
    
    fileprivate lazy var toolBar: InputAccessoryToolBar = {
        return InputAccessoryToolBar(doneHandler: {
            self.editDone()
        }, cancelHandler: {
            self.editCancel()
        })
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        nameField.inputAccessoryView = toolBar
        nameField.textColor = UIColor.textTint
        countLabel.textColor = UIColor.textTint
        nameField.text = nil
        countLabel.text = nil
        
        nameField.font = UIFont.menlo(ofSize: 17)
        nameField.isEnabled = false
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
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
    
    fileprivate func editDone() {
        tagName = nameField.text ?? ""
        editDoneHandler?(tagName)
        
        couldEndEdit = true
        nameField.resignFirstResponder()
    }
    
    fileprivate func editCancel() {
        nameField.text = tagName
        couldEndEdit = true
        nameField.resignFirstResponder()
    }
}

// MARK: - TextField Delegate

extension TagListCell: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        editDone()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        nameField.isEnabled = false
        couldEndEdit = false
    }
    
    // 防止第三方收起键盘
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return couldEndEdit
    }
}
