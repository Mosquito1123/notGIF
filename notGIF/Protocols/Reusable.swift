//
//  Reusable.swift
//  notGIF
//
//  Created by ooatuoo on 2017/6/7.
//  Copyright © 2017年 xyz. All rights reserved.
//

import UIKit

protocol Reusable: class {
    static var ng_reuseIdentifier: String { get }
}

extension UITableViewCell: Reusable {
    static var ng_reuseIdentifier: String {
        return String(describing: self)
    }
}

extension UICollectionReusableView: Reusable {
    static var ng_reuseIdentifier: String {
        return String(describing: self)
    }
}
