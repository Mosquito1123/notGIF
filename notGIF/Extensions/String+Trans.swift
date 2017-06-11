//
//  String+Trans.swift
//  notGIF
//
//  Created by Atuooo on 11/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import Foundation

extension String {
    
    static var trans_promptGetIt: String {
        return NSLocalizedString("prompt.get_it", comment: "")
    }
    
    static var trans_promptTitleNoAccountFound: String {
        return NSLocalizedString("prompt.get_it", comment: "")
    }
    
    static func trans_promptTitleNoAccountFound(of type: String) -> String {
        return ""
    }
    
    static var trans_promptAccountAccessRejected: String {
        return NSLocalizedString("prompt.account_access_rejected", comment: "")
    }
}

extension String {
    
    static var trans_titleAccount: String {
        return NSLocalizedString("title.account", comment: "")
    }
    
    static var trans_titleCancel: String {
        return NSLocalizedString("title.cancel", comment: "")
    }
    
    static var trans_titlePost: String {
        return NSLocalizedString("title.post", comment: "")
    }
    
    static var trans_promptError: String {
        return NSLocalizedString("prompt.error", comment: "")
    }
}
