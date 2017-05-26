//
//  NGWeakProxy.swift
//  notGIF
//
//  Created by ooatuoo on 2017/5/13.
//  Copyright © 2017年 xyz. All rights reserved.
//

import Foundation

class NGWeakProxy: NSObject {
    
    weak var target: NSObjectProtocol?
    
    init(target: NSObjectProtocol) {
        
        self.target = target
        super.init()
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        return (target?.responds(to: aSelector) ?? false) || super.responds(to: aSelector)
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return target
    }
}
