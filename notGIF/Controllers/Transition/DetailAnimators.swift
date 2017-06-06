//
//  DetailAnimators.swift
//  notGIF
//
//  Created by ooatuoo on 2017/5/8.
//  Copyright © 2017年 xyz. All rights reserved.
//

import UIKit

fileprivate let duration = 0.7
fileprivate let maxHeight = kScreenHeight - 64 - 120

class PushDetailAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    var fromRect: CGRect!
    var transitionImage: UIImage!
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from),
            let toView = transitionContext.view(forKey: .to) else {
            return 
        }
        
        fromView.alpha = 1
        toView.alpha = 0
        
        var imageViewW = kScreenWidth
        var imageViewH = kScreenWidth / transitionImage.size.width * transitionImage.size.height
        
        if imageViewH > maxHeight {
            imageViewH = maxHeight
            imageViewW = maxHeight / transitionImage.size.height * transitionImage.size.width
        }
        
        let finalFrame = CGRect(x: (kScreenWidth-imageViewW)/2, y: (kScreenHeight-imageViewH)/2, width: imageViewW, height: imageViewH)
        
        let imageView = UIImageView(frame: fromRect)
        imageView.contentMode = .scaleAspectFit
        imageView.image = transitionImage
        
        let container = transitionContext.containerView
        
        container.insertSubview(toView, belowSubview: fromView)
        container.addSubview(imageView)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
            
            fromView.alpha = 0
            toView.alpha = 1
            
            imageView.frame = finalFrame
            
        }) { _ in
            
            imageView.alpha = 0
            imageView.removeFromSuperview()
            
            let success = !transitionContext.transitionWasCancelled
            transitionContext.completeTransition(success)
        }
    }
}

class PopDetailAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    var beginFrame: CGRect!
    var finalFrame: CGRect!
    var popImage: UIImage!
    
    var isStartFromEdgePan: Bool = true
    
    var maskImageView: UIImageView!
    
    deinit {
        print("pop detail animator deinited .......")
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let fromView = transitionContext.view(forKey: .from),
            let toView = transitionContext.view(forKey: .to) else {
                return
        }
        
        print("is start from edge pan: \(isStartFromEdgePan)")

        maskImageView = UIImageView(image: popImage)
        maskImageView.contentMode = .scaleAspectFit
        maskImageView.frame = beginFrame
        
//        toView.alpha = 0
        fromView.alpha = 1
        
        let container = transitionContext.containerView
        container.addSubview(toView)
//        container.insertSubview(toView, belowSubview: fromView)
        container.addSubview(maskImageView)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: [], animations: { 
            
            fromView.alpha = 0
            toView.alpha = 1
            
            if self.isStartFromEdgePan {
                self.maskImageView.frame = self.finalFrame
            }
            
        }) { _ in
            
            if self.isStartFromEdgePan {
                self.maskImageView.alpha = 0
                self.maskImageView.removeFromSuperview()
            }
            
            let success = !transitionContext.transitionWasCancelled

            if self.isStartFromEdgePan {
                transitionContext.completeTransition(success)
            } else {
                
                UIView.animate(withDuration: 0.3, animations: { 
                    
                    self.maskImageView.frame = success ? self.finalFrame : self.beginFrame
                    
                }, completion: { _ in
                    
                    self.maskImageView.alpha = 0
                    self.maskImageView.removeFromSuperview()
                    
                    transitionContext.completeTransition(success)
                })
            }
        }
    }
    
    func updateFrame(with offsetY: CGFloat) {
        maskImageView.frame.origin.y = beginFrame.origin.y + offsetY
    }
}
