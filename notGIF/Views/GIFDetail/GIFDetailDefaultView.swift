//
//  GIFDetailDefaultView.swift
//  notGIF
//
//  Created by Atuooo on 21/07/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

class GIFDetailDefaultView: UIView {

    fileprivate lazy var imageView: UIImageView = {
        let view = UIImageView(image: #imageLiteral(resourceName: "icon_no_result"))
        view.tintColor = UIColor.textTint.withAlphaComponent(0.5)
        return view
    }()
    
    fileprivate lazy var promptLabel: UILabel = {
        let label = UILabel()
        label.text = String.trans_promptNoGIF
        label.font = UIFont.menlo(ofSize: 16)
        label.textColor = UIColor.textTint.withAlphaComponent(0.8)
        label.textAlignment = .center
        return label
    }()
    
    init() {
        super.init(frame: CGRect(x: 0, y: 120, width: kScreenWidth, height: 200))
        
        addSubview(imageView)
        addSubview(promptLabel)
        
        imageView.snp.makeConstraints { make in
            make.top.centerX.equalTo(self)
        }
        
        promptLabel.snp.makeConstraints { make in
            make.right.left.equalTo(self)
            make.top.equalTo(imageView.snp.bottom).offset(10)
        }
    }
    
    public func addTo(_ view: UIView) {
        alpha = 0
        view.addSubview(self)

        UIView.animate(withDuration: 0.2) {
            self.alpha = 1
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
