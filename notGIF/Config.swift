//
//  Config.swift
//  notGIF
//
//  Created by Atuooo on 26/05/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

final public class Config {

    static let appGroupID   = "group.xyz.atuo.notGIF"
    
    static let defaultTagID = "not.all.gif.tagId"
    
    static let urlScheme    = "notGIF://"
    
    static let appleID      = "1069688631"
    
    static let appStoreCommentURL = "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=\(Config.appleID)&pageNumber=0&sortOrdering=2&mt=8"
    
    static let reportEmail  = "aaatuooo@gmail.com"
    
    static let sideBarWidth = 0.72 * kScreenWidth    // -> Main.storybord
    
    static let maxCustomActionCount: Int = 5
    
    static var isChinese: Bool {
        return Locale.current.languageCode == "zh"
    }
    
    static var version: String {
        let info = Bundle.main.infoDictionary
        return info?["CFBundleShortVersionString"] as? String ?? "Unknown"   // kCFBundleVersionKey
    }
}

// MARK: - Notification
extension Notification.Name {
    static let didSelectTag     = Notification.Name("Config.Notification.didSelectTag")
    static let hideStatusBar    = Notification.Name("Config.Notification.hideStatusBar")
    static let playSpeedChanged = Notification.Name("Config.Notification.playSpeedChanged")
}

// MARK: - Enum
public enum PlaySpeedInList: Int, CustomStringConvertible {
    case normal
    case slow
    
    var value: TimeInterval? {
        switch self {
        case .normal:   return nil
        case .slow:     return 0.2
        }
    }
    
    public var description: String {
        switch self {
        case .normal:   return String.trans_titleNormal
        case .slow:     return String.trans_titleSlow
        }
    }
}

// MARK: - Color
extension UIColor {
    static let textTint     = UIColor.hex(0xfbfbfb)
    static let barTint      = UIColor.hex(0x010101)
    
    static let sideBarBg    = UIColor.hex(0x0d0d0d)
    static let commonBg     = UIColor.hex(0x080808)     // 0x181818
    
    static let editYellow   = UIColor.hex(0xfe9402)
    static let deleteRed    = UIColor.hex(0xe74c3c)     // #f8523a
    
    static let successBlue  = UIColor.hex(0x3498db)     // 0x345479
    static let failRed      = UIColor.deleteRed
    
    static let darkText     = UIColor.hex(0x666666)
    static let lightText    = UIColor.hex(0x999999)     // 0x7f8c8d
}

// MARK: - Font
extension UIFont {
    
    // nav title: /jif/
    class func kenia(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: "Kenia-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    // notGIF slogan
    class func shojumaru(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: "Shojumaru-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    class func menlo(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: "Menlo", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    class func localized(ofSize size: CGFloat) -> UIFont {
        return Config.isChinese ? UIFont.systemFont(ofSize: size, weight: 16) : menlo(ofSize: size)
    }
}

// MARK: - Typealias
public typealias CommonHandler = (() -> Void)
public typealias CommonCompletion = () -> Void


