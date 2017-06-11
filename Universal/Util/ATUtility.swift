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

