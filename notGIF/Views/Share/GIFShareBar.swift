//
//  GIFShareBar.swift
//  notGIF
//
//  Created by Atuooo on 10/10/2016.
//  Copyright © 2016 xyz. All rights reserved.
//

import UIKit

private let itemSize = CGFloat(58)

class GIFShareBar: UIView {
    var shareHandler: ((ShareType) -> Void)?
    
    private var shareTypes: [ShareType] = [.more, .twitter, .weibo, .wechat, .message]
    private var shareButtons = [UIButton]()
    private var showedIndex = 0
    
    override var isHidden: Bool {
        didSet {
            UIView.animate(withDuration: 0.3, animations: {
                self.frame.origin.y = self.isHidden ? kScreenHeight : kScreenHeight - itemSize
            })
        }
    }
    
    init() {
        super.init(frame: CGRect(x: 0, y: kScreenHeight - itemSize, width: kScreenWidth, height: itemSize))
        
        if !OpenShare.canOpen(.wechat) {
            shareTypes.remove(.wechat)
        }
        
        for i in 0 ..< shareTypes.count {
            let button = UIButton(iconCode: shareTypes[i].iconCode, color: .tintColor, fontSize: 28)
            button.addTarget(self, action: #selector(shareButtonClicked(sender:)), for: .touchUpInside)
            button.frame.size = CGSize(width: itemSize, height: itemSize)
            button.frame.origin = CGPoint(x: CGFloat(i) * itemSize, y: 0)
            
            button.transform = CGAffineTransform(translationX: 0, y: itemSize * 2)
            button.tag = shareTypes[i].rawValue
            
            shareButtons.append(button)
            addSubview(button)
        }
    }
    
    func shareButtonClicked(sender: UIButton) {
        guard let shareType = ShareType(rawValue: sender.tag) else { return }
        shareHandler?(shareType)
    }

    public func animate() {
        
        for i in 0..<shareButtons.count {
            let button = shareButtons[i]
            UIView.animate(withDuration: 0.7, delay: Double(i) * 0.04, usingSpringWithDamping: 0.7, initialSpringVelocity: 10, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
                button.transform = .identity
            }, completion: nil)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
