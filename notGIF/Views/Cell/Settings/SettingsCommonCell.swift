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
    
    fileprivate lazy var separator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.hex(0xececec).withAlphaComponent(0.5)
        return view
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        
        tintColor = UIColor.textTint.withAlphaComponent(0.9)
        backgroundColor = UIColor.commonBg
        contentView.backgroundColor = UIColor.commonBg
        
        makeUI()
    }
    
    public func configureWith(_ text: String, hideSeparator: Bool) {
        titleLabel.text = text
        separator.isHidden = hideSeparator
        accessoryType = .disclosureIndicator
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func makeUI() {
        addSubview(separator)
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(18)
            make.centerY.equalTo(contentView)
        }
        
        separator.snp.makeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(-15)
            make.height.equalTo(0.5)
            make.bottom.equalTo(0)
        }
    }
}
