//
//  UITableView+NG.swift
//  notGIF
//
//  Created by ooatuoo on 2017/6/7.
//  Copyright © 2017年 xyz. All rights reserved.
//

import UIKit

extension UITableView {
    func registerClassOf<T: UITableViewCell>(_: T.Type) where T: Reusable {
        register(T.self, forCellReuseIdentifier: T.ng_reuseIdentifier)
    }
    
    func dequeueReusableCell<T: UITableViewCell>() -> T {
        guard let cell = dequeueReusableCell(withIdentifier: T.ng_reuseIdentifier) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.ng_reuseIdentifier)")
        }
        
        return cell
    }
}
