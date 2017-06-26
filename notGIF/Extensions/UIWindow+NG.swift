//
//  UIWindow+NG.swift
//  notGIF
//
//  Created by Atuooo on 26/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

extension UIWindow {
    // http://stackoverflow.com/a/27153956/4696807
    
    func set(rootViewController newRootViewController: UIViewController) {
        
        let previousViewController = rootViewController
        
        let transition = CATransition()
        transition.type = kCATransitionFade
        layer.add(transition, forKey: kCATransition)
        
        rootViewController = newRootViewController
        
        // Update status bar appearance using the new view controllers appearance - animate if needed
        if UIView.areAnimationsEnabled {
            UIView.animate(withDuration: CATransaction.animationDuration()) {
                newRootViewController.setNeedsStatusBarAppearanceUpdate()
            }
        } else {
            newRootViewController.setNeedsStatusBarAppearanceUpdate()
        }
        
        /// The presenting view controllers view doesn't get removed from the window as its currently transistioning and presenting a view controller
        if let transitionViewClass = NSClassFromString("UITransitionView") {
            for subview in subviews where subview.isKind(of: transitionViewClass) {
                subview.removeFromSuperview()
            }
        }
        
        if let previousViewController = previousViewController {
            // Allow the view controller to be deallocated
            previousViewController.dismiss(animated: false) {
                // Remove the root view in case its still showing
                previousViewController.view.removeFromSuperview()
            }
        }
    }
}
