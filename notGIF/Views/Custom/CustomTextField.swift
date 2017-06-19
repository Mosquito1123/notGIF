//
//  CustomTextField.swift
//  notGIF
//
//  Created by ooatuoo on 2017/6/7.
//  Copyright © 2017年 xyz. All rights reserved.
//

import UIKit

fileprivate let leftViewSize: CGFloat = 20
fileprivate let padding: CGFloat = 10

class CustomTextField: UITextField {
    
    public var addTagHandler: ((String) -> Void)?
    fileprivate var couldEndEdit: Bool = false
    
    fileprivate lazy var toolBar: CustomToolBar = {
        return CustomToolBar(doneHandler: {
            self.editDone()
        }, cancelHandler: {
            self.editCancel()
        })
    }()
    
    fileprivate lazy var attPlaceHolder: NSAttributedString = {
        let att: [String : Any] = [
            NSFontAttributeName: UIFont.menlo(ofSize: 17),
            NSForegroundColorAttributeName: UIColor.textTint
        ]
        return NSAttributedString(string: String.trans_tag, attributes: att)
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        tintColor = UIColor.textTint
        
        let leftImageView = UIImageView(image: #imageLiteral(resourceName: "icon_add_tag"))
        leftImageView.tintColor = UIColor.textTint
        leftImageView.frame = CGRect(x: 0, y: 0, width: leftViewSize, height: leftViewSize)
        
        leftImageView.contentMode = .scaleAspectFit
        leftView = leftImageView
        leftViewMode = .always
        
//        let att: [String : Any] = [
//            NSFontAttributeName: UIFont.menlo(ofSize: 17),
//            NSForegroundColorAttributeName: UIColor.textTint
//        ]
//        
//        attributedPlaceholder = NSAttributedString(string: String.trans_tag, attributes: att)
        
        attributedPlaceholder = attPlaceHolder
        
        textColor = UIColor.textTint
        inputAccessoryView = toolBar
        
        delegate = self
    }

    // MARK: - Tool Bar Handler
    
    fileprivate func editDone() {
        addTagHandler?(text ?? "")
        
        text = nil
        couldEndEdit = true
        resignFirstResponder()
    }
    
    fileprivate func editCancel() {
        text = nil
        couldEndEdit = true
        resignFirstResponder()
    }
    
    // MARK: - Custom Layout
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let textWidth = attPlaceHolder.size().width
        
        let originX = bounds.width/2-textWidth/2+padding/2+leftViewSize/2
        return CGRect(x: originX, y: 0, width: textWidth, height: bounds.height)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: leftViewSize+padding, y: 0, width: bounds.width-leftViewSize-padding, height: bounds.height)
    }
    
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        if isEditing {
            return CGRect(x: 0, y: 0, width: leftViewSize, height: bounds.height)
            
        } else {
            let textWidth = attPlaceHolder.size().width
            let originX = (bounds.width-textWidth-padding-leftViewSize)/2
            return CGRect(x: originX, y: 0, width: leftViewSize, height: bounds.height)
        }
    }
}

// MARK: - Delegate

extension CustomTextField: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        attributedPlaceholder = nil
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        editDone()
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return couldEndEdit
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        attributedPlaceholder = attPlaceHolder
        couldEndEdit = false
    }
}
