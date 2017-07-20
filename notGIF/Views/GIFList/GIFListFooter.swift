//
//  GIFListFooter.swift
//  notGIF
//
//  Created by Atuooo on 14/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit
import Photos

enum GIFListFooterType {
    case showCount(Tag?)
    case needAuthorize
}

class GIFListFooter: UICollectionReusableView {
    
    static let height: CGFloat = 80
    
    fileprivate lazy var tagNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.lightText
        label.textAlignment = .center
        label.font = UIFont.menlo(ofSize: 16)
        return label
    }()
    
    fileprivate lazy var countLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.lightText
        label.textAlignment = .center
        label.font = UIFont.menlo(ofSize: 13)
        return label
    }()
    
    fileprivate lazy var goSettingsButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        button.titleLabel?.font = UIFont.menlo(ofSize: 18)
        button.tintColor = UIColor.textTint
        button.setTitleColor(UIColor.textTint, for: .normal)
        button.setImage(#imageLiteral(resourceName: "icon_settings"), for: .normal)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        button.setTitle(String.trans_titleOpenSettings, for: .normal)
        button.addTarget(self, action: #selector(goSettingsButtonClicked), for: .touchUpInside)
        return button
    }()
    
    fileprivate lazy var promptLabel: UILabel = {
        let label = UILabel()
        label.text = String.trans_needPhotosPermission
        label.textColor = UIColor.lightText
        label.font = UIFont.menlo(ofSize: 16)
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
    }
    
    public func update(with type: GIFListFooterType) {
        switch type {
        case .showCount(let tag):
            if let tag = tag {
                showCount(of: tag)
            }
        case .needAuthorize:
            showNeedPermisson()
        }
    }
    
    fileprivate func showCount(of tag: Tag) {
        
        if let _ = promptLabel.superview {
            promptLabel.removeFromSuperview()
            goSettingsButton.removeFromSuperview()
        }
        
        let fHeihgt = GIFListFooter.height, lableH: CGFloat = 16
        tagNameLabel.frame = CGRect(x: 0, y: fHeihgt/2-lableH-2, width: kScreenWidth, height: lableH)
        countLabel.frame = CGRect(x: 0, y: fHeihgt/2+2, width: kScreenWidth, height: lableH)
        
        tagNameLabel.text = tag.localNameStr
        countLabel.text = "\(tag.gifs.count) GIFs"
        
        addSubview(tagNameLabel)
        addSubview(countLabel)
    }
    
    fileprivate func showNeedPermisson() {
        let fHeihgt = GIFListFooter.height, lableH: CGFloat = 16
        promptLabel.frame = CGRect(x: 0, y: fHeihgt/2-lableH/2, width: kScreenWidth, height: lableH)
        goSettingsButton.frame = CGRect(x: 0, y: fHeihgt-20, width: kScreenWidth, height: 20)
        
        addSubview(promptLabel)
        addSubview(goSettingsButton)
    }
    
    func goSettingsButtonClicked() {
        var urlStr = Config.urlScheme
        #if CONTAINER_TARGET
            urlStr = UIApplicationOpenSettingsURLString
        #endif
        
        if let url = URL(string: urlStr) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
