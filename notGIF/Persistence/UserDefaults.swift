//
//  UserDefaults.swift
//  notGIF
//
//  Created by ooatuoo on 2017/5/27.
//  Copyright © 2017年 xyz. All rights reserved.
//

import Foundation

private let have_fetch_gif_key          = "notGIF_have_fetched"
private let last_select_tag_key         = "notGIF_last_select_tag_id"
private let play_control_state_key      = "notGIF_play_control_state"
private let have_show_intro_key         = "notGIF_have_show_intro"

final public class NGUserDefaults {
    
    static let defaults = UserDefaults(suiteName: Config.appGroupID)!

    static var haveFetched: Bool {
        set {
            defaults.set(newValue, forKey: have_fetch_gif_key)
        }
        get {
            return defaults.bool(forKey: have_fetch_gif_key)
        }
    }
    
    static var lastSelectTagID: String {
        set {
            defaults.set(newValue, forKey: last_select_tag_key)
        }
        get {
            return defaults.string(forKey: last_select_tag_key) ?? Config.defaultTagID
        }
    }
    
    static var shouldAutoPause: Bool {
        set {
            defaults.set(newValue, forKey: play_control_state_key)
        }
        get {
            return defaults.bool(forKey: play_control_state_key)
        }
    }
    
    static var haveShowIntro: Bool {
        set {
            defaults.set(newValue, forKey: have_show_intro_key)
        }
        get {
            return defaults.bool(forKey: have_show_intro_key)
        }
    }
}
