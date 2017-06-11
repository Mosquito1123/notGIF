//
//  StatusAlert.swift
//  notGIF
//
//  Created by Atuooo on 14/10/2016.
//  Copyright © 2016 xyz. All rights reserved.
//

import UIKit

final class StatusBarToast {
    
    enum DisplayDirection: Int {
        case top
        case bottom
        case right
        case left
    }
    
    enum DisplayType: Int {
        case replace
        case overlay
    }
    
    static var shared = StatusBarToast()
    
    static var textFont:            UIFont          = UIFont.systemFont(ofSize: 12)
    static var textColor:           UIColor         = UIColor.textTint
    static var backgroundColor:     UIColor         = UIColor.bgColor
    static var duration:            TimeInterval    = 3
    static var animationDuration:   TimeInterval    = 0.4
    
    fileprivate var isShowing: Bool = false
    fileprivate var message: String!
    
    fileprivate var window: ToastWindow!
    fileprivate var messageLabel: UILabel!
        fileprivate var statusBarView: UIView!
    
    fileprivate var dismissTimer: DispatchSourceTimer?
    
    func show(_ message: String, duration: TimeInterval = StatusBarToast.duration, type: DisplayType = .overlay, direction: DisplayDirection = .top, textColor: UIColor = StatusBarToast.textColor) {
        
        guard duration != 0 else { return }
        
        dismissTimer?.cancel()
        
        self.message = message
        
        if isShowing {
            
            switch type {
                
            case .replace:
                messageLabel.textColor = textColor
                messageLabel.text = message
                
            case .overlay:
                
                dismissToast(animated: false)
                showToast(with: message, from: direction, textColor: textColor)
            }
            
        } else {
            
            showToast(with: message, from: direction, textColor: textColor)
        }
        
        setDismissTimer(with: duration)
    }
    
    fileprivate func showToast(with message: String, from direction: DisplayDirection, textColor: UIColor) {
        
        isShowing = true
        makeToastUI()
        
        messageLabel.textColor = textColor
        messageLabel.text = message
        window.isHidden = false
        
        UIView.animate(withDuration: StatusBarToast.animationDuration,
                       delay: 0,
                       options: [.beginFromCurrentState],
                       animations: {
                        
            self.messageLabel.frame.origin.y = 0
            self.statusBarView.frame = CGRect(x: 0, y: kStatusHeight, width: kScreenWidth, height: 0)
                        
        }, completion: nil)
    }
    
    fileprivate func dismissToast(animated: Bool) {
        func deinitUI() {
            messageLabel.isUserInteractionEnabled = false
            window.isHidden = true
            window = nil
            messageLabel = nil
            statusBarView = nil
            isShowing = false
            
            dismissTimer = nil
        }
        
        if animated {
            
            UIView.animate(withDuration: StatusBarToast.animationDuration,
                           delay: 0,
                           options: [.beginFromCurrentState],
                           animations: {
                            
                self.messageLabel.frame.origin.y = -kStatusHeight
                self.statusBarView.frame = CGRect(x: 0, y: 0, width: kScreenWidth, height: kStatusHeight)
                            
            }, completion: { _ in
                deinitUI()
            })
            
        } else {
            
            deinitUI()
        }
    }
    
    fileprivate func setDismissTimer(with duration: TimeInterval) {
        guard let timer = dismissTimer, !timer.isCancelled else {
            
            dismissTimer = DispatchSource.makeTimerSource(queue: .main)
            dismissTimer?.setEventHandler(handler: { [weak self] in
                self?.dismissToast(animated: true)
            })
            
            dismissTimer?.scheduleOneshot(deadline: .now() + duration)
            dismissTimer?.resume()
            return
        }
        
        dismissTimer?.scheduleOneshot(deadline: .now() + duration)
        
    }
    
    fileprivate func makeToastUI() {
        window = ToastWindow()
        
        let statusBarRect = CGRect(x: 0, y: 0, width: kScreenWidth, height: kStatusHeight)
        messageLabel = UILabel(frame: statusBarRect)
        messageLabel.font = StatusBarToast.textFont
        messageLabel.textAlignment = .center
        messageLabel.textColor = StatusBarToast.textColor
        messageLabel.backgroundColor = StatusBarToast.backgroundColor
        
        let tapToDismissGes = UITapGestureRecognizer(target: self, action: #selector(StatusBarToast.tapToDismissGesAction))
        messageLabel.addGestureRecognizer(tapToDismissGes)
        messageLabel.isUserInteractionEnabled = true
        
        let statusBarSnapView = UIScreen.main.snapshotView(afterScreenUpdates: true)
        statusBarView = UIView(frame: statusBarRect)
        for subview in statusBarView.subviews {
            subview.removeFromSuperview()
        }

        statusBarView.clipsToBounds = true
        statusBarView.addSubview(statusBarSnapView)
        
        messageLabel.frame.origin.y = -kStatusHeight
        
        window.rootViewController?.view.addSubview(statusBarView)
        window.rootViewController?.view.addSubview(messageLabel)
    }
    
    @objc fileprivate func tapToDismissGesAction() {
        dismissTimer = nil
        dismissToast(animated: true)
    }
    
    init() { }
}

fileprivate class ToastWindow: UIWindow {
    fileprivate override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if UIApplication.shared.statusBarFrame.contains(point) {
            return super.hitTest(point, with: event)
        } else {
            return nil
        }
    }
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        
        backgroundColor = .clear
        windowLevel = UIWindowLevelStatusBar
        isUserInteractionEnabled = true
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        rootViewController = ToastViewController()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class ToastViewController: UIViewController {
    fileprivate override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}


