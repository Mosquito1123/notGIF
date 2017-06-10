//
//  UserDefaults.swift
//  notGIF
//
//  Created by ooatuoo on 2017/5/27.
//  Copyright © 2017年 xyz. All rights reserved.
//

import Foundation

private let haveFetchedKey      = "notGIF_have_fetched"
private let lastSelectTagIDKey  = "notGIF_last_select_tag_id"

final public class NGUserDefaults {
    
    static let defaults = UserDefaults(suiteName: Config.appGroupID)!

    static var haveFetched: Bool {
        set {
            defaults.set(newValue, forKey: haveFetchedKey)
        }
        get {
            return defaults.bool(forKey: haveFetchedKey)
        }
    }
    
    static var lastSelectTagID: String {
        set {
            defaults.set(newValue, forKey: lastSelectTagIDKey)
        }
        get {
            return defaults.string(forKey: lastSelectTagIDKey) ?? Config.defaultTagID
        }
    }
}
