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
}

extension StatusBarToast {
    
    class func show(_ scene: ToastShowScene) {
        var message = ""
        var displayType: DisplayType = .overlay
        var duration: TimeInterval = 5.0
        var textColor: UIColor = UIColor.textTint
        
        switch scene {
        case .posting:
            message = "sending ... "
            duration = 7.0
            StatusBarToast.backgroundColor = UIColor.bgColor
            
        case .postSuccess:
            message = "send successfully ..."
            StatusBarToast.backgroundColor = UIColor.successBlue
            
        case .postFailed(let error):
            message = "failed: \(error)"
            StatusBarToast.backgroundColor = UIColor.failRed
            
        case .requestFailed:
            message = "request failed"
            StatusBarToast.backgroundColor = UIColor.failRed
        }
        
        DispatchQueue.main.async {
            StatusBarToast.shared.show(message, duration: duration, type: displayType, direction: .top, textColor: textColor)
        }
    }
}
