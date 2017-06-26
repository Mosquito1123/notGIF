//
//  UIImage+NG.swift
//  notGIF
//
//  Created by Atuooo on 11/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

extension UIImage {
    public func aspectFill(toSize: CGSize) -> UIImage {
        var cropArea = CGRect.zero
        var scale = CGFloat(0)
        
        if size.height > size.width {
            cropArea = CGRect(x: 0, y: (size.height-size.width) / 2, width: size.width, height: size.width)
            scale = size.width / toSize.width
        } else {
            cropArea = CGRect(x: (size.width - size.height)/2, y: 0, width: size.height, height: size.height)
            scale = size.height / toSize.width
        }
        
        let cropImageRef = cgImage!.cropping(to: cropArea)
        return UIImage(cgImage: cropImageRef!, scale: scale, orientation: .up)
    }
}
