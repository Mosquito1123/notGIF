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
private let should_auto_play_key        = "notGIF_should_auto_play"
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
    
    static var shouldAutoPlay: Bool {
        set {
            defaults.set(newValue, forKey: should_auto_play_key)
        }
        get {
            return defaults.bool(forKey: should_auto_play_key)
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
