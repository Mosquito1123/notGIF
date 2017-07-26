//
//  String+NG.swift
//  notGIF
//
//  Created by Atuooo on 07/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

extension String {
    var isUseful: Bool {
        return !trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension TimeInterval {
    var timeStr: String {
        return String(format: "%.2f", self)
    }
}

extension Int {
    var str: String {
        return self < 10 ? "0\(self)" : "\(self)"
    }
    
    var byteStr: String {
        let kb = self / 1024
        return kb >= 1024 ? String(format: "%.1f MB", Float(kb) / 1024) : "\(kb) kB"
    }
}
