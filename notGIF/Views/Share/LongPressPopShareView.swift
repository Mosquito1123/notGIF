//
//  LongPressPopShareView.swift
//  notGIF
//
//  Created by ooatuoo on 2017/6/16.
//  Copyright © 2017年 xyz. All rights reserved.
//

import UIKit

class LongPressPopShareView: UIView {

    fileprivate var iconViews: [UIView] = []
    fileprivate var iconTriggerRects: [CGRect] = []
    fileprivate var shareTypes: [ShareType] = [.more, .twitter, .weibo, .wechat, .tag]
    fileprivate var hasChanged: Bool = false
    
    fileprivate var cellMaskRect: CGRect = .zero
    fileprivate var isForIntro: Bool = false
    
    init(popOrigin: CGPoint, cellRect: CGRect, frame: CGRect = UIScreen.main.bounds, isForIntro: Bool = false) {
        super.init(frame: frame)
        backgroundColor = UIColor.red.withAlphaComponent(0.7)
        alpha = 0
        
        self.isForIntro = isForIntro
        
        cellMaskRect = cellRect

        if !OpenShare.canOpen(.wechat) {
//            shareTypes.remove(.wechat)
        }
        
        let iconS: CGFloat = 36
        let padding: CGFloat = 16
        let spaceV: CGFloat = 12
        let count = shareTypes.count
        let totalW = CGFloat(count) * iconS + CGFloat(count - 1) * padding
        
        var beignOx: CGFloat
        
        if totalW/2 + popOrigin.x > (kScreenWidth - padding/2) {
            beignOx = kScreenWidth - totalW - padding / 2
        } else if popOrigin.x - totalW/2 < padding / 2 {
            beignOx = padding/2
        } else {
            beignOx = popOrigin.x - totalW/2
        }
        
        let baseOriginY: CGFloat = cellRect.minY - spaceV - iconS
        
        for i in 0..<count {
            
            let iconViewFrame = CGRect(x: beignOx, y: baseOriginY, width: iconS, height: iconS)
            let fontSize: CGFloat = shareTypes[i] == .tag ? 25 : 28
            let iconView = UILabel(iconCode: shareTypes[i].iconCode, color: UIColor.textTint, fontSize: fontSize)
            iconView.frame = iconViewFrame
            beignOx += iconS + padding
            iconView.contentMode = .scaleAspectFit
            iconView.alpha = 0
                        
            let iconTriggerRect = CGRect(x: iconViewFrame.minX - padding/2, y: baseOriginY, width: iconS+padding, height: cellRect.maxY - iconViewFrame.minY)
            iconTriggerRects.append(iconTriggerRect)
            iconViews.append(iconView)
            addSubview(iconView)
        }
        
        restore()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if !isForIntro {
            animate()
        }
    }
    
    public func animate() {
        let duration = isForIntro ? 1.2 : 0.6

        UIView.animate(withDuration: 10) {
            self.alpha = 1
//            self.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        }
        
        UIView.animate(withDuration: 10, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: [.curveEaseOut], animations: {
            self.iconViews.forEach { $0.alpha = 1 ; $0.transform = .identity }
        }, completion: nil)
    }
    
    public func restore() {
        backgroundColor = UIColor.black.withAlphaComponent(0)
        
        for i in 0..<iconViews.count {
            let iconView = iconViews[i]
            iconView.alpha = 0
            
            if i % 2 == 0 {
                let transformT = CGAffineTransform(translationX: 0, y: iconView.frame.width)
                let transformR = CGAffineTransform(rotationAngle: CGFloat.pi * 0.3)
                let transfromS = CGAffineTransform(scaleX: 0.2, y: 0.2)
                
                iconView.transform = transformT.concatenating(transfromS).concatenating(transformR)
                
            } else {
                let transformT = CGAffineTransform(translationX: 0, y: -iconView.frame.width)
                let transformR = CGAffineTransform(rotationAngle: CGFloat.pi * 0.7)
                let transfromS = CGAffineTransform(scaleX: 0.3, y: 0.3)
                
                iconView.transform = transformT.concatenating(transfromS).concatenating(transformR)
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.clear.cgColor)
        context?.setBlendMode(.clear)
        context?.fillEllipse(in: cellMaskRect.insetBy(dx: 4, dy: 2))
    }
    
    public func update(with offset: CGPoint) {
        hasChanged = true
        
        let transfromS = CGAffineTransform(scaleX: 1.2, y: 1.2)
        let transformT = CGAffineTransform(translationX: 0, y: -12)
        let transform = transformT.concatenating(transfromS)
        
        let index = iconTriggerRects.index(where: { $0.contains(offset) })
        
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: [.curveEaseInOut], animations: {
            
            for i in 0..<self.iconViews.count {
                if index == i {
                    self.iconViews[i].transform = transform
                } else {
                    self.iconViews[i].transform = .identity
                }
            }
            
        }, completion: nil)
    }
    
    public func end(with offset: CGPoint) -> ShareType? {
        UIView.animate(withDuration: 0.2, animations: { 
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
        
        guard hasChanged else { return nil }
        
        if let index = iconTriggerRects.index(where: { $0.contains(offset) }) {
            return shareTypes[index]
        } else {
            return nil
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
