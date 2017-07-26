//
//  GIFActionType.swift
//  notGIF
//
//  Created by Atuooo on 19/07/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

public enum GIFActionType: Hashable, Equatable {
    case shareTo(ShareType)
    case showAllFrame
    case editTag
    
    public enum ShareType: Int {
        case more
        case twitter
        case weibo
        case wechat
        case message
        
        var icon: UIImage {
            switch self {
            case .more:     return #imageLiteral(resourceName: "icon_share")
            case .twitter:  return #imageLiteral(resourceName: "icon_twitter")
            case .weibo:    return #imageLiteral(resourceName: "icon_weibo")
            case .wechat:   return #imageLiteral(resourceName: "icon_wechat")
            case .message:  return #imageLiteral(resourceName: "icon_message")
            }
        }
        
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
    
    // MARK: - Hash
    public var hashValue: Int {
        switch self {
        case .shareTo(let sType):
            return sType.rawValue
        case .editTag:
            return 111
        case .showAllFrame:
            return 222
        }
    }
    
    // MARK: - Init
    static func initWith(_ rawValue: Int) -> GIFActionType? {
        switch rawValue {
        case 0...4:
            guard let shareType = ShareType(rawValue: rawValue) else { return nil }
            return .shareTo(shareType)
            
        case 111:
            return .editTag
            
        case 222:
            return .showAllFrame
            
        default:
            return nil
        }
    }
    
    static var defaultActions: [GIFActionType] {
        var actions: [GIFActionType] = [
            .shareTo(.more), .shareTo(.twitter), .shareTo(.weibo), .shareTo(.wechat),
            .editTag, .showAllFrame
        ]
        
        if OpenShare.canOpen(.wechat) {
            actions.remove(.shareTo(.twitter))
        } else {
            actions.remove(.shareTo(.wechat))
        }
        
        return actions
    }
    
    static var allActionValues: [Int] {
        return [0, 1, 2, 3, 4, 111, 222]
    }
    
    // MARK: - Helper    
    var icon: UIImage {
        switch self {
        case .shareTo(let sType):   return sType.icon
        case .showAllFrame:         return #imageLiteral(resourceName: "icon_all_frame")
        case .editTag:              return #imageLiteral(resourceName: "icon_tag")
        }
    }
}

public func ==(lhs: GIFActionType, rhs: GIFActionType) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

