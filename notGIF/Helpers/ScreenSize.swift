//
//  ScreenSize.swift
//  notGIF
//
//  Created by Atuooo on 03/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

public let kScreenSize = ScreenSize.shared.size
public let kScreenWidth = ScreenSize.shared.size.width
public let kScreenHeight = ScreenSize.shared.size.height

class ScreenSize {
    static let shared = ScreenSize()
    
    let size: CGSize = {
        var ss = UIScreen.main.bounds.size
        if ss.height < ss.width {
            let tmp = ss.width
            ss.width = ss.height
            ss.height = tmp
        }
        return ss
    }()
    
    private init() {}
}
