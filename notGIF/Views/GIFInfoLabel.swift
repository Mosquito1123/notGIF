//
//  GIFInfoLabel.swift
//  notGIF
//
//  Created by Atuooo on 12/10/2016.
//  Copyright © 2016 xyz. All rights reserved.
//

import UIKit

class GIFInfoLabel: UILabel {
    var info: String = "" {
        didSet {
            let components = info.components(separatedBy: "\n")
            guard !components.isEmpty else { return }
            
            let attString = NSMutableAttributedString(string: info)
            let aRange = (info as NSString).range(of: components[0])
            let bRange = (info as NSString).range(of: components[1])
            attString.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 16), range: aRange)
            attString.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: 11), range: bRange)
            
            attributedText = attString
        }
    }

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        
        textColor = .textTint
        textAlignment = .center
        numberOfLines = 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
