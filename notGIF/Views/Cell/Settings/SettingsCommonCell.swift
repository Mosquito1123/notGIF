//
//  SettingsCommonCell.swift
//  notGIF
//
//  Created by Atuooo on 25/07/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

class SettingsCommonCell: UITableViewCell {
    
    fileprivate lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.textTint
        label.font = UIFont.menlo(ofSize: 16)
        return label
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        
        tintColor = UIColor.textTint.withAlphaComponent(0.9)
        backgroundColor = UIColor.commonBg
        contentView.backgroundColor = UIColor.commonBg
        
        makeUI()
    }
    
    public func configureWith(_ text: String) {
        titleLabel.text = text
        accessoryType = .disclosureIndicator
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func makeUI() {
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(18)
            make.centerY.equalTo(contentView)
        }
    }
}
