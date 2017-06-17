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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let leftImageView = UIImageView(image: #imageLiteral(resourceName: "icon_add_tag"))
        leftImageView.tintColor = UIColor.textTint
        leftImageView.frame = CGRect(x: 0, y: 0, width: leftViewSize, height: leftViewSize)
        
        leftImageView.contentMode = .scaleAspectFit
        leftView = leftImageView
        leftViewMode = .always
        
        let att: [String : Any] = [
            NSFontAttributeName: UIFont.menlo(ofSize: 17),
            NSForegroundColorAttributeName: UIColor.textTint
        ]
        
        attributedPlaceholder = NSAttributedString(string: String.trans_tag, attributes: att)
        
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
        var textWidth: CGFloat
        if let attPlaceHolder = attributedPlaceholder {
            textWidth = attPlaceHolder.size().width
        } else {
            let str = String.trans_tag
            textWidth = str.size(attributes: defaultTextAttributes).width
        }
        
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
            
            var textWidth: CGFloat
            if let attPlaceHolder = attributedPlaceholder {
                textWidth = attPlaceHolder.size().width
            } else {
                let str = String.trans_tag
                textWidth = str.size(attributes: defaultTextAttributes).width
            }

            let originX = (bounds.width-textWidth-padding-leftViewSize)/2
            return CGRect(x: originX, y: 0, width: leftViewSize, height: bounds.height)
        }
    }
}

// MARK: - Delegate

extension CustomTextField: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        editDone()
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return couldEndEdit
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        couldEndEdit = false
    }
}
