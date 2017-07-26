//
//  SpeedSettingCell.swift
//  notGIF
//
//  Created by Atuooo on 27/07/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

class SpeedSettingCell: UITableViewCell {

    fileprivate lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = String.trans_titlePlaySpeedInList
        label.textColor = UIColor.textTint
        label.font = UIFont.menlo(ofSize: 16)
        return label
    }()
    
    public lazy var speedLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.textTint.withAlphaComponent(0.7)
        label.font = UIFont.menlo(ofSize: 15)
        label.textAlignment = .right
        return label
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        
        contentView.backgroundColor = UIColor.commonBg
        makeUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func makeUI() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(speedLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(18)
            make.centerY.equalTo(contentView)
        }
        
        speedLabel.snp.makeConstraints { make in
            make.right.equalTo(-15)
            make.centerY.equalTo(contentView)
        }
    }
}
