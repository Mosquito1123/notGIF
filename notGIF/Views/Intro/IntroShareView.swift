//
//  IntroShareView.swift
//  notGIF
//
//  Created by Atuooo on 24/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

class IntroShareView: UIImageView, Intro {

    fileprivate var animated = false
    fileprivate var popShareView: LongPressPopShareView!
    
    init() {
        // 750 * 1130 - 0.7     pos: 0, 0.338, 0.57, 0.285
        let imageW = kScreenWidth * 0.7
        let imageH = imageW/750*1130
        let rect = CGRect(x: 27, y: (kScreenHeight-imageH)/2, width: kScreenWidth, height: imageH)
        super.init(frame: rect)
        
        contentMode = .scaleAspectFit
        image = #imageLiteral(resourceName: "plain")
        isUserInteractionEnabled = false
        
        let imageRect = CGRect(x: 0.15*kScreenWidth, y: imageH*0.338, width: imageW*0.57, height: imageH*0.285)
        popShareView = LongPressPopShareView(popOrigin: CGPoint(x: imageRect.midX, y: imageRect.minY), cellRect: imageRect, frame: CGRect(origin: .zero, size: rect.size), isForIntro: true)
        popShareView.isUserInteractionEnabled = false
        popShareView.alpha = 0
        
        addSubview(popShareView)
        
    }
    
    func animate() {
        guard !animated else { return }
        animated = true
        
        popShareView.alpha = 1
        popShareView.animate()
    }
    
    func restore() {
        guard animated else { return }
        animated = false
        
        popShareView.restore()
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
