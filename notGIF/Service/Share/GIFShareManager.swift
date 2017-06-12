//
//  GIFShareManager.swift
//  notGIF
//
//  Created by Atuooo on 11/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit
import MessageUI
import ReachabilitySwift
import MobileCoreServices

public enum ShareType: Int {
    case more    = 23
    case twitter
    case weibo
    case wechat
    case message
    
    var iconCode: FontUnicode {
        switch self {
        case .more:     return .share
        case .twitter:  return .twitter
        case .weibo:    return .weibo
        case .wechat:   return .wechat
        case .message:  return .message
        }
    }
}

class GIFShareManager {
    
    class func shareGIF(of id: String, to type: ShareType) {
        guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else { return }
        
        HUD.show(.requestData)
        
        NotGIFLibrary.shared.requestGIFData(of: id) { gifInfo in
            
            guard let gifInfo = gifInfo else {
                HUD.hide();
                StatusBarToast.show(.gifNotPrepared)
                return
            }
            
            switch type {
                
            case .weibo, .twitter:
                guard (Reachability()?.isReachable ?? false) else {
                    HUD.hide()
                    Alert.show(.badNetwork)
                    return
                }
                
                let composeVC = ComposeViewController(shareType: type, with: gifInfo)
                composeVC.modalPresentationStyle = .overCurrentContext
                DispatchQueue.main.safeAsync {
                    rootVC.present(composeVC, animated: true) { HUD.hide() }
                }
                
            case .wechat:
                OpenShare.shareGIF(with: gifInfo, to: .wechat)
                HUD.hide()
                
            case .more:
                let activityVC = UIActivityViewController(activityItems: [gifInfo.data], applicationActivities: nil)
                
                DispatchQueue.main.safeAsync {
                    rootVC.present(activityVC, animated: true) { HUD.hide() }
                }
                
            case .message:
                if let messageVC = MessageComposeViewController(gifData: gifInfo.data) {
                    DispatchQueue.main.safeAsync {
                        rootVC.present(messageVC, animated: true) { HUD.hide() }
                    }
                    
                } else {
                    HUD.hide()
                    Alert.show(.messageUnsupport)
                }
            }
        }
    }
    
}
