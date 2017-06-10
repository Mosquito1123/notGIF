//
//  ATUtility.swift
//  notGIF
//
//  Created by Atuooo on 10/10/2016.
//  Copyright © 2016 xyz. All rights reserved.
//

import UIKit

public let gifIDs_Key = "atuo.notGIF.gifIDs"

extension Int {
    var byteString: String {
        let kb = self / 1024
        return kb >= 1024 ? String(format: "%.1f MB", Float(kb) / 1024) : "\(kb) kB"
    }
}


extension String {
    func singleLineWidth(with font: UIFont) -> CGFloat {
        return (self as NSString).boundingRect(with: CGSize(width: .max, height: .max),
                                               options: [.usesFontLeading, .usesLineFragmentOrigin],
                                               attributes: [NSFontAttributeName: font],
                                               context: nil).size.width
    }
}

extension IndexSet {
    subscript(index: Int) -> Int {
        return self[self.index(startIndex, offsetBy: index)]
    }
}

extension Array where Element: Equatable {
    mutating func remove(object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }
}

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
