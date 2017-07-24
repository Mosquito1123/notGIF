//
//  NavigationTitleLabel.swift
//  notGIF
//
//  Created by Atuooo on 23/07/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

class NavigationTitleLabel: UILabel {
    override var text: String? {
        didSet {
            super.text = text
            sizeToFit()
            layoutIfNeeded()
        }
    }
    
    init(title: String? = "") {
        super.init(frame: .zero)
        
        text = title
        textColor = UIColor.textTint
        textAlignment = .center
        font = UIFont.localized(ofSize: 18)
        numberOfLines = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
