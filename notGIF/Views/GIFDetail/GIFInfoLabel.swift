//
//  CustomLabel.swift
//  notGIF
//
//  Created by Atuooo on 12/10/2016.
//  Copyright © 2016 xyz. All rights reserved.
//

import UIKit

class GIFInfoLabel: UILabel {
    
    fileprivate var aFont: UIFont
    fileprivate var bFont: UIFont
    
    var info: String = "" {
        didSet {
            let components = info.components(separatedBy: "\n")
            guard components.count == 2 else { return }
            
            let attString = NSMutableAttributedString(string: info)
            let aRange = (info as NSString).range(of: components[0])
            let bRange = (info as NSString).range(of: components[1])
            attString.addAttribute(NSFontAttributeName, value: aFont, range: aRange)
            attString.addAttribute(NSFontAttributeName, value: bFont, range: bRange)
            
            attributedText = attString
        }
    }

    init(aFont: UIFont, bFont: UIFont) {
        self.aFont = aFont
        self.bFont = bFont
        super.init(frame: CGRect(x: 0, y: 0, width: kScreenWidth - 100, height: 40))
        
        textColor = .textTint
        textAlignment = .center
        numberOfLines = 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
