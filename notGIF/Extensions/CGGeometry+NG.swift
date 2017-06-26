//
//  CGPoint+NG.swift
//  notGIF
//
//  Created by Atuooo on 10/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

extension CGPoint {
    
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
}

extension CGRect {
    func insetBy(scale: CGFloat) -> CGRect {
        return self.insetBy(dx: size.width * scale, dy: size.height * scale)
    }
}
