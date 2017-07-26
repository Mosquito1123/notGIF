//
//  IntroDetailView.swift
//  notGIF
//
//  Created by Atuooo on 26/07/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

class IntroDetailView: UIView, Intro {
    
    fileprivate var animated = false

    fileprivate lazy var demoImageView: UIImageView = {
        let view = UIImageView(image: #imageLiteral(resourceName: "intro_detail_plain"))
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    fileprivate lazy var toolImagView: UIImageView = {
        let view = UIImageView(image: #imageLiteral(resourceName: "intro_tool_demo"))
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    fileprivate lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = String.trans_introDetail
        label.font = UIFont.systemFont(ofSize: 24, weight: 16)
        label.textAlignment = .center
        label.textColor = UIColor.textTint
        return label
    }()
    
    fileprivate lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.text = String.trans_introDetailMessage
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.textColor = UIColor.lightText
        return label
    }()

    init() {
        super.init(frame: UIScreen.main.bounds)
        backgroundColor = UIColor.black

        makeUI()
    }
    
    // MARK: - Intro
    func animate() {
        guard !animated else { return }
        animated = true

        UIView.animate(withDuration: 0.6, delay: 0.1, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.6, options: [.curveEaseInOut], animations: {
            self.toolImagView.alpha = 1
            self.toolImagView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }, completion: nil)
    }
    
    func restore() {
        guard animated else { return }
        animated = false
        toolImagView.alpha = 0
        toolImagView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
    }
    
    func show() {
        transform = .identity
        alpha = 1
    }
    
    func hide(toLeft: Bool) {
        transform = CGAffineTransform(translationX: toLeft ? -kScreenWidth : kScreenWidth, y: 0)
        alpha = 0
    }
    
    // MARK: - Helper
    
    fileprivate func makeUI() {
        addSubview(demoImageView)
        addSubview(toolImagView)
        addSubview(titleLabel)
        addSubview(messageLabel)
        
        messageLabel.snp.makeConstraints { make in
            make.right.left.equalTo(0)
            make.bottom.equalTo(-kScreenHeight*0.08)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.right.left.equalTo(0)
            make.bottom.equalTo(messageLabel.snp.top).offset(-6)
        }
        
        demoImageView.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.equalTo(18)
            make.height.equalTo(kScreenHeight*0.7)
        }
        
        toolImagView.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.centerY.equalTo(demoImageView.snp.bottom).offset(-20)
            make.width.equalTo(kScreenWidth)
        }
        
        toolImagView.alpha = 0
        toolImagView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
