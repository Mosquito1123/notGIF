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
    
    public var hashValue: Int {
        switch self {
        case .shareTo(let sType):
            return sType.rawValue
        case .editTag:
            return 99
        case .showAllFrame:
            return 233
        }
    }
    
    func image(of size: CGFloat, color: UIColor = UIColor.textTint) -> UIImage {
        switch self {
        case .shareTo(let sType):
            return UIImage.iCon(ofCode: sType.iconCode, size: .init(width: size, height: size), color: color)
        case .showAllFrame:
            return #imageLiteral(resourceName: "icon_show_frame")
        case .editTag:
            return UIImage.iCon(ofCode: FontUnicode.tag, size: .init(width: size*1.2, height: size), color: color)
        }
    }
    
    public enum ShareType: Int {
        case more
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
}

public func ==(lhs: GIFActionType, rhs: GIFActionType) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

