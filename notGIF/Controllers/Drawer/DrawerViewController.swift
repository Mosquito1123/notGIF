//
//  DrawerViewController.swift
//  notGIF
//
//  Created by ooatuoo on 2017/6/1.
//  Copyright © 2017年 xyz. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift

fileprivate let sideBarWidth: CGFloat = Config.sideBarWidth
fileprivate let scaleFactor:  CGFloat = 80 / kScreenHeight
fileprivate let animDuration: TimeInterval = 0.6

class DrawerViewController: UIViewController {

    @IBOutlet var dissmisTapGes: UITapGestureRecognizer!
    @IBOutlet var sidePanGes: UIPanGestureRecognizer!
    
    @IBOutlet weak var sideBarContainer: UIView!
    @IBOutlet weak var mainContainer: UIView! {
        didSet {
            mainContainer.layer.shadowColor = UIColor.black.cgColor
            mainContainer.layer.shadowOffset = CGSize(width: -2.0, height: -2.0)
            mainContainer.layer.shadowOpacity = 0.33
        }
    }
    
    fileprivate var shouldHideStatusBar: Bool = false
    fileprivate var gesBeginOffsetX: CGFloat = 0

    fileprivate var isShowing: Bool = false {
        didSet {
            dissmisTapGes.isEnabled = isShowing
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(DrawerViewController.setStatusBarHidden(noti:)), name: .hideStatusBar, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Update Status Bar
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var prefersStatusBarHidden: Bool {
        return shouldHideStatusBar
    }
    
    func setStatusBarHidden(noti: Notification) {
        guard let shouldHide = noti.object as? Bool else { return }
        shouldHideStatusBar = shouldHide
        setNeedsStatusBarAppearanceUpdate()
    }
    
    // MARK: - Gesture Handler
    
    @IBAction func sidePanGesHandler(_ sender: UIPanGestureRecognizer) {
        let transitionX = sender.translation(in: view).x
        let offsetX = max(min(kScreenWidth, gesBeginOffsetX + transitionX), 0)
        
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
        if isShowing {
            if offset <= sideBarWidth*0.7 || velocityX < -500 {
                dismissSideBar(with: offset, velocityX: velocityX)
            } else {
                showSideBar(with: offset, velocityX: velocityX)
            }
            
        } else {
            if offset >= sideBarWidth*0.3 || velocityX > 500 {
                showSideBar(with: offset, velocityX: velocityX)
            } else {
                dismissSideBar(with: offset, velocityX: velocityX)
            }
        }
    }
    
    public func showSideBar(with offset: CGFloat = 0, velocityX: CGFloat = 0) {
        let xDiff = abs(offset - sideBarWidth)
        var velocity = xDiff == 0 ? 0 : abs(velocityX) / xDiff
        if velocity < 10 { velocity = 0.6 }
        let finalScale = 1 - (sideBarWidth / kScreenWidth) * scaleFactor
        
        UIView.animate(withDuration: animDuration,
                       delay: 0,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: velocity,
                       options: [.curveEaseIn],
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
        
        UIView.animate(withDuration: animDuration*0.8,
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
        guard !IQKeyboardManager.sharedManager().keyboardShowing else { return false}
        
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
