//
//  NotGIFImageView+Load.swift
//  notGIF
//
//  Created by Atuooo on 03/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

// MARK: - Associated Object
fileprivate var localIDKey: Void?
fileprivate var imageTaskKey: Void?
fileprivate var indicatorKey: Void?

extension NotGIFImageView {
    
    /// Get the image localIdentifier binded to this image view.
    fileprivate var localID: String {
        return objc_getAssociatedObject(self, &localIDKey) as! String
    }
    
    fileprivate func setLocalID(_ localID: String) {
        objc_setAssociatedObject(self, &localIDKey, localID, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    fileprivate var imageTask: DispatchWorkItem? {
        return objc_getAssociatedObject(self, &imageTaskKey) as? DispatchWorkItem
    }
    
    fileprivate func setImageTask(_ task: DispatchWorkItem?) {
        objc_setAssociatedObject(self, &imageTaskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    fileprivate var indicator: UIActivityIndicatorView? {
        get {
            if let indicatorView = (objc_getAssociatedObject(self, &indicatorKey) as? UIActivityIndicatorView) {
                return indicatorView
            } else {
                let indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
                indicatorView.isHidden = true
                indicatorView.hidesWhenStopped = true
                indicatorView.center = CGPoint(x: bounds.midX, y: bounds.midY)
                indicatorView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin, .flexibleTopMargin]
                addSubview(indicatorView)
                
                objc_setAssociatedObject(self, &indicatorKey, indicatorView, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return indicatorView
            }
        }
    }
    
    public func setGIFImage(with gifID: String, shouldPlay: Bool, completionHandler: ((NotGIFImage) -> Void)? = nil) {
        let activityIndicator = indicator
        activityIndicator?.startAnimating()
        
        setLocalID(gifID)
        
        let task = NotGIFLibrary.shared.retrieveGIF(with: gifID) {[weak self] (gif, retrievedID, withTransition) in
            
            guard let sSelf = self, retrievedID == sSelf.localID
                else { activityIndicator?.stopAnimationAndHide(); return }
            
            sSelf.setImageTask(nil)
            
            let setImage = {
                sSelf.animateImage = gif
                shouldPlay ? sSelf.startAnimating() : sSelf.stopAnimating()
            }
            
            DispatchQueue.main.safeAsync {
                if withTransition {
                    UIView.transition(with: sSelf, duration: 0.0, options: [], animations: {
                        activityIndicator?.stopAnimationAndHide()
                    }, completion: { _ in
                        UIView.transition(with: sSelf, duration: 0.4, options: .transitionCrossDissolve, animations: {
                            setImage()
                        }, completion: { _ in
                            completionHandler?(gif)
                        })
                    })
                    
                } else {
                    activityIndicator?.stopAnimationAndHide()
                    setImage()
                    completionHandler?(gif)
                }
            }
        }
        
        if task == nil {
            activityIndicator?.stopAnimationAndHide()
        }
        
        setImageTask(task)
    }
    
    public func cancelTask() {
        imageTask?.cancel()
    }
}

fileprivate extension UIActivityIndicatorView {
    func stopAnimationAndHide() {
        stopAnimating()
        isHidden = true
    }
}
