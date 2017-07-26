//
//  IntroShareView.swift
//  notGIF
//
//  Created by Atuooo on 24/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

class IntroShareView: UIView, Intro {

    public var goMainHandler: CommonHandler?
    
    fileprivate var animated = false
    fileprivate var popShareView: GIFListActionView!
    
    fileprivate lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = String.trans_titleIntroShare
        label.font = UIFont.systemFont(ofSize: 24, weight: 16)
        label.textAlignment = .center
        label.textColor = UIColor.textTint
        return label
    }()
    
    fileprivate lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.text = String.trans_titleIntroShareMessage
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.textColor = UIColor.lightText
        return label
    }()
    
    fileprivate lazy var goButton: UIButton = {
        let button = UIButton()
        button.alpha = 0
        button.isEnabled = false
        button.setTitle("Let's Go", for: .normal)
        button.titleLabel?.font = UIFont.menlo(ofSize: 18)
        button.setTitleColor(UIColor.textTint, for: .normal)
        button.addTarget(self, action: #selector(IntroShareView.goButtonClickHanler), for: .touchUpInside)
        return button
    }()
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        
        backgroundColor = UIColor.black
        
        // 750 * 1130 - 0.7     pos: 0, 0.338, 0.57, 0.285
        let imageScale: CGFloat = 0.7
        let imageW = kScreenWidth * imageScale
        let imageH = imageW/750*1130
        let rect = CGRect(x: 27, y: kScreenHeight*0.22, width: kScreenWidth, height: imageH)

        let imageView = UIImageView(image: #imageLiteral(resourceName: "intro_share_plain"))
        imageView.frame = rect
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        
        let imageRect = CGRect(x: (0.5-imageScale/2)*kScreenWidth, y: imageH*0.338, width: imageW*0.57, height: imageH*0.285)
        popShareView = GIFListActionView(popOrigin: CGPoint(x: imageRect.midX, y: imageRect.minY), cellRect: imageRect, frame: CGRect(origin: .zero, size: rect.size), isForIntro: true)
        popShareView.isUserInteractionEnabled = false
        
        imageView.addSubview(popShareView)
        
        addSubview(titleLabel)
        addSubview(messageLabel)
        addSubview(goButton)
        
        titleLabel.snp.makeConstraints { make in
            make.right.left.equalTo(0)
            make.top.equalTo(kScreenHeight*0.08)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.right.left.equalTo(0)
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
        }
        
        goButton.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.bottom.equalTo(-24)
        }
    }
    
    func goButtonClickHanler() {
        goMainHandler?()
    }
    
    // MARK: - Intro Protocol
    
    func animate() {
        guard !animated else { return }
        animated = true
        
        popShareView.animate()
        UIView.animate(withDuration: 0.45, delay: 0.7, options: [], animations: {
            self.goButton.alpha = 1
        }) { _ in
            self.goButton.isEnabled = true
        }
    }
    
    func restore() {
        guard animated else { return }
        animated = false
        
        popShareView.restore()
        goButton.alpha = 0
        goButton.isEnabled = false
    }
    
    func show() {
        transform = .identity
        alpha = 1
    }
    
    func hide(toLeft: Bool) {
        transform = CGAffineTransform(translationX: toLeft ? -kScreenWidth : kScreenWidth, y: 0)
        alpha = 0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
