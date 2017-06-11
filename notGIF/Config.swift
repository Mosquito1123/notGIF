//
//  Config.swift
//  notGIF
//
//  Created by Atuooo on 26/05/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

final public class Config {

    static let appGroupID = "group.atuo-xyz.notGIF"
    
    static let defaultTagID = "not.all.gif.tagId"
    
    static let sideBarWidth = 0.72 * kScreenWidth    // -> Main.storybord    
}

extension Notification.Name {
    static let didSelectTag = Notification.Name("Config.Notification.didSelectTag")
}

extension UIColor {
    static let textTint     = UIColor.hex(0xfbfbfb)
    static let editYellow   = UIColor.hex(0xfe9402)
    static let deleteRed    = UIColor.hex(0xf8523a)
    
    static let successBlue  = UIColor.blue
    static let failRed      = UIColor.deleteRed
    
    static let darkText     = UIColor.hex(0x666666)
    static let bgColor      = UIColor.hex(0x1d1d1d)
}

extension UIFont {
    
    // nav title: /jif/
    class func kenia(ofSize size: CGFloat) -> UIFont? {
        return UIFont(name: "Kenia-Regular", size: size)
    }
    
    // notGIF slogan
    class func shojumaru(ofSize size: CGFloat) -> UIFont? {
        return UIFont(name: "Shojumaru-Regular", size: size)
    }
    
    class func menlo(ofSize size: CGFloat) -> UIFont? {
        return UIFont(name: "Menlo", size: size)
    }
}
