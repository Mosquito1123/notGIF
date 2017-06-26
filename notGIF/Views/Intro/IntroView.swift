//
//  IntroView.swift
//  notGIF
//
//  Created by Atuooo on 24/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

protocol Intro {
    func animate()
    func restore()
    func show()
    func hide(toLeft: Bool)
}

class IntroView: UIView, Intro {
    
    func animate() {
        
    }
    
    func restore() {
        
    }
    
    func show() {
        transform = .identity
        alpha = 1
    }
    
    func hide(toLeft: Bool) {
        transform = CGAffineTransform(translationX: toLeft ? -kScreenWidth : kScreenWidth, y: 0)
        alpha = 0
    }
}
