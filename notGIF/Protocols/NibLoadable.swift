//
//  NibLoadable.swift
//  notGIF
//
//  Created by Atuooo on 24/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

protocol NibLoadable {
    
    static var ng_nibName: String { get }
}

extension UITableViewCell: NibLoadable {
    
    static var ng_nibName: String {
        return String(describing: self)
    }
}
