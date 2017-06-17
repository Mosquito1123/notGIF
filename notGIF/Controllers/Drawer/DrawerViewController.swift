//
//  DrawerViewController.swift
//  notGIF
//
//  Created by ooatuoo on 2017/6/1.
//  Copyright © 2017年 xyz. All rights reserved.
//

import UIKit

fileprivate let sideBarWidth: CGFloat = Config.sideBarWidth
fileprivate let scaleFactor:  CGFloat = 80 / kScreenHeight
fileprivate let animDuration: TimeInterval = 0.6

class DrawerViewController: UIViewController {

    @IBOutlet var dissmisTapGes: UITapGestureRecognizer!
    @IBOutlet var sidePanGes: UIPanGestureRecognizer!
    @IBOutlet weak var sideBarContainer: UIView!
    @IBOutlet weak var mainContainer: UIView!
    
    fileprivate var gesBeginOffsetX: CGFloat = 0

    fileprivate var isShowing: Bool = false {
        didSet {
            dissmisTapGes.isEnabled = isShowing
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    // MARK: - Gesture Handler
    
    @IBAction func sidePanGesHandler(_ sender: UIPanGestureRecognizer) {
        let transitionX = sender.translation(in: view).x
        let offsetX = gesBeginOffsetX + transitionX
        
        switch sender.state {
        case .began:
            gesBeginOffsetX = mainContainer.frame.origin.x

        case .changed:
            let scale = 1 - (offsetX / kScreenWidth) * scaleFactor
            mainContainer.transform = CGAffineTransform(translationX: offsetX, y: 0)
                                        .scaledBy(x: 1, y: scale)
        
        case .cancelled, .ended, .failed:
            let velocity = sender.velocity(in: view)
            endMoveSideBar(with: offsetX, velocityX: velocity.x)
            
        default:
            break
        }
    }
    
    @IBAction func dismissTapGesHandler(_ sender: UITapGestureRecognizer) {
        dismissSideBar()
    }
    
    // MARK: - Show & Dismiss
    
    fileprivate func endMoveSideBar(with offset: CGFloat, velocityX: CGFloat) {
        if offset >= sideBarWidth * 0.3 {
            showSideBar(with: offset, velocityX: velocityX)
        } else {
            dismissSideBar(with: offset, velocityX: velocityX)
        }
    }
    
    public func showSideBar(with offset: CGFloat = 0, velocityX: CGFloat = 0) {
        let xDiff = abs(offset - sideBarWidth)
        let velocity = xDiff == 0 ? 0 : abs(velocityX) / xDiff
        let finalScale = 1 - (sideBarWidth / kScreenWidth) * scaleFactor
        
        UIView.animate(withDuration: animDuration,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: velocity,
                       options: [],
                       animations: {
                        
            self.mainContainer.transform = CGAffineTransform(translationX: sideBarWidth, y: 0)
                                            .scaledBy(x: 1, y: finalScale)
        }) { _ in
            
            self.mainContainer.isUserInteractionEnabled = false
            self.isShowing = true
        }
    }
    
    public func dismissSideBar(with offset: CGFloat = sideBarWidth, velocityX: CGFloat = 0) {
        
        let velocity = offset == 0 ? 0 : abs(velocityX) / abs(offset)
        
        UIView.animate(withDuration: animDuration,
                       delay: 0,
                       usingSpringWithDamping: 1,
                       initialSpringVelocity: velocity,
                       options: [],
                       animations: {
                        
            self.mainContainer.transform = .identity
            
        }) { _ in
            
            self.mainContainer.isUserInteractionEnabled = true
            self.isShowing = false
        }
    }
    
    public func showOrDissmissSideBar() {
        isShowing ? dismissSideBar() : showSideBar()
    }
}

// MARK: - Gesture Delegate
extension DrawerViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === sidePanGes {
            if isShowing {
                let location = sidePanGes.location(in: view)
                return mainContainer.frame.contains(location)
            } else {
                return sidePanGes.velocity(in: mainContainer).x > 0
            }
            
        } else if gestureRecognizer === dissmisTapGes {
            let tapLocation = dissmisTapGes.location(in: view)
            return isShowing && mainContainer.frame.contains(tapLocation)
        }
        
        return true
    }
}
