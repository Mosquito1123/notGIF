//
//  UIColor+NG.swift
//  notGIF
//
//  Created by Atuooo on 03/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

extension UIColor {

    @nonobjc static let tintRed   = UIColor.hex(0xF4511E)
    @nonobjc static let tintBlue  = UIColor.hex(0x039BE5)
    @nonobjc static let tintBar   = UIColor.hex(0x1C1C1C, alpha: 0.5)
    @nonobjc static let tintColor = UIColor.hex(0xFBFBFB, alpha: 0.95)
    
    public class func hex(_ hex: NSInteger, alpha: CGFloat = 1.0) -> UIColor {
        return UIColor(red: ((CGFloat)((hex & 0xFF0000) >> 16))/255.0,
                       green: ((CGFloat)((hex & 0xFF00) >> 8))/255.0,
                       blue: ((CGFloat)(hex & 0xFF))/255.0, alpha: alpha)
    }
}
