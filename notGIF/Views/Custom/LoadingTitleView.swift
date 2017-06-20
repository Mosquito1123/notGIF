//
//  LoadingTitleView.swift
//  notGIF
//
//  Created by Atuooo on 19/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

class LoadingTitleView: UIView {

    fileprivate let width: CGFloat = kScreenWidth/2
    
    fileprivate lazy var titleLabel: UILabel = {
        let label = UILabel(frame: self.bounds)
        label.text = "/jif/"
        label.font = UIFont.kenia(ofSize: 26)
        label.textColor = .textTint
        label.textAlignment = .center
        return label
    }()
    
    fileprivate lazy var loadingView: UIView = {
        let container = UIView(frame: self.bounds)
        
        let label = UILabel()
        label.text = String.trans_titleUpdating
        label.font = Config.isChinese ? UIFont.systemFont(ofSize: 18, weight: 20) : UIFont.menlo(ofSize: 18)
        label.textColor = .textTint
        label.textAlignment = .center
        label.sizeToFit()
                
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        indicator.color = UIColor.textTint
        indicator.startAnimating()
        
        let labelSize = label.frame.size
        let originX = (self.bounds.width-20-labelSize.width-8)/2
        indicator.frame = CGRect(x: originX, y: 0, width: 20, height: self.bounds.height)
        label.frame = CGRect(x: originX+20+8, y: 0, width: labelSize.width, height: self.bounds.height)
        container.addSubview(indicator)
        container.addSubview(label)
        
        return container
    }()
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: width, height: 40))
        update(isLoading: false)
    }
    
    public func update(isLoading: Bool) {
        if isLoading {
            addSubview(loadingView)
            titleLabel.removeFromSuperview()
        } else {
            loadingView.removeFromSuperview()
            addSubview(titleLabel)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
