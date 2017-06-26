//
//  StatusBarToast+NG.swift
//  notGIF
//
//  Created by Atuooo on 11/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

public enum ToastShowScene {
    case posting
    case postSuccess
    case postFailed(String)
    case requestFailed
    case gifNotPrepared
    case sthError
}

extension StatusBarToast {
    
    class func show(_ scene: ToastShowScene) {
        var message = ""
        let displayType: DisplayType = .overlay
        var duration: TimeInterval = 5.0
        let textColor: UIColor = UIColor.textTint
        
        switch scene {
        case .posting:
            message = String.trans_sending
            duration = 60
            StatusBarToast.backgroundColor = UIColor.bgColor
            
        case .postSuccess:
            message = String.trans_postSuccess
            StatusBarToast.backgroundColor = UIColor.successBlue
            
        case .postFailed(let error):
            message = String.trans_postFailed + error
            StatusBarToast.backgroundColor = UIColor.failRed
            
        case .requestFailed:
            message = String.trans_requestFailed
            StatusBarToast.backgroundColor = UIColor.failRed
            
        case .sthError:
            message = String.trans_promptError
            StatusBarToast.backgroundColor = UIColor.failRed
            
        case .gifNotPrepared:
            message = String.trans_gifNotPrepared
            StatusBarToast.backgroundColor = UIColor.failRed
        }
        
        DispatchQueue.main.async {
            StatusBarToast.shared.show(message, duration: duration, type: displayType, direction: .top, textColor: textColor)
        }
    }
}
