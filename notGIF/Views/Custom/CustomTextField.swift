//
//  CustomTextField.swift
//  notGIF
//
//  Created by ooatuoo on 2017/6/7.
//  Copyright © 2017年 xyz. All rights reserved.
//

import UIKit

class CustomTextField: UITextField {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        addTarget(self, action: #selector(CustomTextField.textFieldDidChanged(sender:)), for: .editingChanged)
    }

    func textFieldDidChanged(sender: UITextField) {
        invalidateIntrinsicContentSize()
    }
    
    override var intrinsicContentSize: CGSize {
        if isEditing {
//            let att = [NSFontAttributeName: UIFont.menlo(ofSize: 17)]
            let textSize = (text ?? "").size(attributes: typingAttributes)  // typingAttributes
            let otherW = (leftView?.bounds.size.width ?? 0) + (rightView?.bounds.size.width ?? 0)
            return CGSize(width: otherW + textSize.width + 2, height: textSize.height)

        } else {
            return super.intrinsicContentSize
        }
    }
}
