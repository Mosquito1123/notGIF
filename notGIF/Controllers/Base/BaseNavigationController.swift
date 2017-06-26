//
//  BaseNavigationController.swift
//  notGIF
//
//  Created by Atuooo on 10/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

class BaseNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bottmLine = getBottomLineView(in: navigationBar)
        bottmLine?.isHidden = true
    }
    
    func getBottomLineView(in view: UIView) -> UIImageView? {
        if view is UIImageView && view.bounds.size.height <= 1.0 {
            return view as? UIImageView
        }
        
        for subView in view.subviews {
            if let imgView = getBottomLineView(in: subView) {
                return imgView
            }
        }
        
        return nil
    }
}
