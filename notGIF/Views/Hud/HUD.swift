//
//  HUD.swift
//  notGIF
//
//  Created by ooatuoo on 2017/6/6.
//  Copyright © 2017年 xyz. All rights reserved.
//

import MBProgressHUD

public enum HUDShowScene {
    case fetchGIF
    case requestData
    
    var message: String {
        switch self {
        case .fetchGIF:
            return String.trans_titleFetching
        case .requestData:
            return String.trans_titlePreparing
        }
    }
}

class HUD {

    class func show(to view: UIView? = nil, _ scene: HUDShowScene) {
        guard let superView = view ?? UIApplication.shared.keyWindow else { return }
        
        let hud = MBProgressHUD.showAdded(to: superView, animated: true)
        hud.removeFromSuperViewOnHide = false
        hud.mode = .indeterminate
        hud.animationType = .fade
        hud.contentColor = .textTint
        hud.bezelView.color = .clear
        hud.bezelView.style = .solidColor
        hud.backgroundView.color = .clear
        
        if scene == .fetchGIF {
            hud.offset = CGPoint(x: 0, y: -superView.frame.height/5)
        }
        
        hud.label.text = scene.message
        hud.label.font = UIFont.menlo(ofSize: 13)
        hud.layer.zPosition = 1
        
        hud.hide(animated: true, afterDelay: 6)
    }
    
    class func hide(in view: UIView? = nil) {
        guard let superView = view ?? UIApplication.shared.keyWindow else { return }
        MBProgressHUD.hide(for: superView, animated: true)
    }
    
    class func show(to view: UIView? = nil, text: String, showCompletionIcon: Bool = true, delay: TimeInterval = 1) {
        guard let superView = view ?? UIApplication.shared.keyWindow else { return }
        
        let hud = MBProgressHUD.showAdded(to: superView, animated: true)
        hud.mode = showCompletionIcon ? .customView : .text
        hud.customView = UILabel(iconCode: .checkO, color: UIColor.textTint, fontSize: 32)
        hud.margin = 18
        hud.contentColor = .textTint
        hud.bezelView.color = .bgColor
        hud.label.text = text
        hud.label.font = UIFont.menlo(ofSize: 15)
        
        hud.hide(animated: true, afterDelay: delay)
    }
}
