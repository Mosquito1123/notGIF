//
//  StatusAlert.swift
//  3DTest
//
//  Created by Atuooo on 14/10/2016.
//  Copyright © 2016 xyz. All rights reserved.
//

import UIKit


public enum ToastState {
    case begin
    case showing
    case end
}

public enum ToastInfoType {
    case `continue`(message: String, shouldLoading: Bool)
    case once(message: String, succeed: Bool)
    case end(message: String, succeed: Bool)
    
    var bgColor: UIColor {
        switch self {
        case .continue:
            return .hex(0x1C1C1C)
        case .once(_, let succeed):
            return succeed ? .tintBlue : .tintRed
        case .end(_, let succeed):
            return succeed ? .tintBlue : .tintRed
        }
    }
    
    var message: String {
        switch self {
        case .continue(let message, _):
            return message
        case .once(let message, _):
            return message
        case .end(let message, _):
            return message
        }
    }
}

private let statusHeight = UIApplication.shared.statusBarFrame.height
private let delayTime = 5.0

final class StatusBarToast {
    static let shared = StatusBarToast()
    
    fileprivate var toastWindow: ToastWindow!
    fileprivate var messageLabel: UILabel!
    fileprivate var statusView: UIView!
    fileprivate var loadingLayer: StatusBarLoadingLayer!
    fileprivate var dismissWortItem: DispatchWorkItem?
    
    fileprivate var state: ToastState!
    fileprivate var showing = false
    fileprivate var dismissing = false
    
    func show(info: ToastInfoType) {
        switch info {
        case .continue:
            if !showing {
                showing = true
                makeToastUI(with: info)
                toastWindow.isHidden = false
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.statusView.frame = CGRect(x: 0, y: statusHeight, width: kScreenWidth, height: 0)
                    self.messageLabel.frame.origin = CGPoint(x: 0, y: 0)
                })
            }
            
        case .once:
            
            if !showing {
                showing = true
                makeToastUI(with: info)
                toastWindow.isHidden = false
                
                dismissWortItem = DispatchWorkItem(block: { [weak self] in
                    self!.dismissing = true
                    self?.dismissToast()
                })
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.statusView.frame = CGRect(x: 0, y: statusHeight, width: kScreenWidth, height: 0)
                    self.messageLabel.frame.origin = CGPoint(x: 0, y: 0)
                    
                }) { done in
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + delayTime, execute: self.dismissWortItem!)
                }
            }
            
        case .end:
            if showing && !dismissing {
                dismissWortItem = DispatchWorkItem(block: { [weak self] in
                    self!.dismissing = true
                    self?.dismissToast()
                })
                
                loadingLayer.removeFromSuperlayer()
                
                DispatchQueue.main.async {
                    self.messageLabel.backgroundColor = info.bgColor
                    self.messageLabel.text = info.message
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: self.dismissWortItem!)

                }
            }
        }
    }

    @objc private func didTap(sender: UITapGestureRecognizer) {
        if !dismissing {
            dismissWortItem?.cancel()
            dismissToast()
        }
    }
    
    private func dismissToast() {
        UIView.animate(withDuration: 0.3, animations: { 
            self.statusView.frame = CGRect(x: 0, y: 0, width: kScreenWidth, height: statusHeight)
            self.messageLabel.frame.origin = CGPoint(x: 0, y: -statusHeight)
            
        }) { done in
            
            self.toastWindow.isHidden = true
            self.messageLabel.removeFromSuperview()
            self.statusView.removeFromSuperview()
            self.messageLabel = nil
            self.statusView = nil
            self.toastWindow = nil
            self.dismissWortItem = nil
            self.showing = false
            self.dismissing = false
        }
    }
    
    private func makeToastUI(with info: ToastInfoType) {
        toastWindow = ToastWindow(frame: UIScreen.main.bounds)
        toastWindow.windowLevel = UIWindowLevelStatusBar
        toastWindow.backgroundColor = .clear
        toastWindow.isUserInteractionEnabled = true
        toastWindow.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        toastWindow.rootViewController = UIViewController()
        
        messageLabel = UILabel(frame: CGRect(x: 0, y: -statusHeight, width: kScreenWidth, height: statusHeight))
        messageLabel.isUserInteractionEnabled = true
        messageLabel.font = .systemFont(ofSize: 12)
        messageLabel.textAlignment = .center
        messageLabel.textColor = .tintColor
        messageLabel.backgroundColor = info.bgColor
        messageLabel.text = info.message
        
        if case .continue(_, let shouldLoading) = info, shouldLoading == true {
            let textWidth = info.message.singleLineWidth(with: .systemFont(ofSize: 12))
            let center = CGPoint(x: (kScreenWidth + textWidth) / 2 + 10, y: statusHeight / 2)
            loadingLayer = StatusBarLoadingLayer(radius: 4, center: center, color: .tintColor)
            messageLabel.layer.addSublayer(loadingLayer)
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(StatusBarToast.didTap(sender:)))
        messageLabel.addGestureRecognizer(tapGesture)
        
        let snapView = UIScreen.main.snapshotView(afterScreenUpdates: true)
        statusView = UIView(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: statusHeight))
        statusView.layer.masksToBounds = true
        statusView.addSubview(snapView)
        
        toastWindow.rootViewController?.view.addSubview(statusView)
        toastWindow.rootViewController?.view.addSubview(messageLabel)
    }
    
    private init() {}
}

private class ToastWindow: UIWindow {
    private override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if UIApplication.shared.statusBarFrame.contains(point) {
            return super.hitTest(point, with: event)
        } else {
            return nil
        }
    }
}


