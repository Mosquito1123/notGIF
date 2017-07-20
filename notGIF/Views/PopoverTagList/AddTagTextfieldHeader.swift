//
//  AddTagTextfieldHeader.swift
//  notGIF
//
//  Created by Atuooo on 17/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit
import SnapKit

class AddTagTextfieldHeader: UIView, UITextFieldDelegate {
    
    fileprivate var couldEndEdit: Bool = false
    fileprivate var addTagHandler: ((String) -> Void)?
    
    fileprivate lazy var textField: CustomTextField = {
        let textField = CustomTextField()
        textField.placeholder = String.trans_promptTapToAddTag
        textField.font = UIFont.menlo(ofSize: 17)
        textField.borderStyle = .none
        textField.textAlignment = .left
        textField.backgroundColor = UIColor.white
        textField.inputAccessoryView = self.toolBar
        textField.delegate = self
        return textField
    }()
    
    fileprivate lazy var toolBar: InputAccessoryToolBar = {
        return InputAccessoryToolBar(doneHandler: {
            self.editDone()
        }, cancelHandler: { 
            self.editCancel()
        })
    }()
    
    init(width: CGFloat, addTagHandler: @escaping (String) -> Void) {
        let textFieldH: CGFloat = 44, padding: CGFloat = 8
        super.init(frame: CGRect(x: 0, y: 0, width: width, height: textFieldH+padding))
        
        self.addTagHandler = addTagHandler
        backgroundColor = UIColor.clear
        
        addSubview(textField)
        
        textField.snp.makeConstraints { make in
            make.top.right.left.equalTo(self)
            make.height.equalTo(textFieldH)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - ToolBar Handler
    
    fileprivate func editDone() {
        addTagHandler?(textField.text ?? "")

        textField.text = nil
        couldEndEdit = true
        textField.resignFirstResponder()
    }
    
    public func editCancel() {
        textField.text = nil
        couldEndEdit = true
        textField.resignFirstResponder()
    }
    
    // MARK: - TextField Delegate
    
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

fileprivate class CustomTextField: UITextField {
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 15, dy: 6)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 15, dy: 6)
    }
}
