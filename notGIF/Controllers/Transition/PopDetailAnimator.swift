//
//  PopDetailAnimator.swift
//  notGIF
//
//  Created by ooatuoo on 2017/6/8.
//  Copyright © 2017年 xyz. All rights reserved.
//

import UIKit

fileprivate let duration = 0.3

class PopDetailAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    public var isTriggeredByPan: Bool = false
    
    fileprivate var imageBeginFrame: CGRect = .zero
    fileprivate var maskImageView: NotGIFImageView!
    
    fileprivate var detailView: UIView!
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let listVC = transitionContext.viewController(forKey: .to) as? GIFListViewController,
              let detailVC = transitionContext.viewController(forKey: .from) as? GIFDetailViewController,
              let detailView = transitionContext.view(forKey: .from),
              let listView = transitionContext.view(forKey: .to)
        else {
            transitionContext.completeTransition(true)
            return
        }
        
        let container = transitionContext.containerView
        container.insertSubview(listView, belowSubview: detailView)
        
        let currentIndex = detailVC.currentIndex
        let currentIP = IndexPath(row: currentIndex, section: 0)
        
        if let detailCell = detailVC.collectionView.cellForItem(at: currentIP) as? GIFDetailCell,
            let listCell = listVC.collectionView.cellForItem(at: currentIP) as? GIFListCell {
            
            self.maskImageView = detailCell.imageView
            self.detailView = detailView
            
            let imageOriginFrame = maskImageView.frame
            imageBeginFrame = imageOriginFrame
            let imageFinalFrame = listVC.collectionView.convert(listCell.frame, to: UIApplication.shared.keyWindow)
            
            listCell.isInTransition = true
            listVC.shouldPlay = true
            listCell.isHidden = true
            listCell.imageView.stopAnimating()
            
            container.addSubview(maskImageView)
        
            listVC.collectionView.alpha = 0
            detailVC.collectionView.alpha = 0
            
            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1, options: [], animations: {
                
                listVC.collectionView.alpha = 1
                
                if !self.isTriggeredByPan {
                    detailView.alpha = 0
                    self.maskImageView.frame = imageFinalFrame
                }
                
            }, completion: { _ in
                
                let isSuccess = !transitionContext.transitionWasCancelled

                let completionHandler = {
                    listCell.isHidden = false
                    
                    if !isSuccess {
                        listCell.isInTransition = false
                        listVC.shouldPlay = false
                        
                        detailView.alpha = 1
                        detailVC.collectionView.alpha = 1

                        self.maskImageView.removeFromSuperview()
                        self.maskImageView.frame = imageOriginFrame
                        detailCell.contentView.insertSubview(self.maskImageView, at: 0)
                        
                    } else {
                        
                        listCell.isInTransition = false
                        self.maskImageView.removeFromSuperview()
                    }
                    
                    transitionContext.completeTransition(isSuccess)
                }
                
                if self.isTriggeredByPan {
  
                    UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1.2, options: [], animations: {
                        
                        if isSuccess {
                            detailView.alpha = 0
                            detailVC.collectionView.alpha = 0
                            self.maskImageView.frame = imageFinalFrame
                            
                            self.maskImageView.stopAnimating()
                            listCell.isInTransition = false
                            listCell.animating(enable: listVC.shouldPlay)
                        
                        } else {
                            
                            self.maskImageView.frame = self.imageBeginFrame
                        }
                        
                    }, completion: { _ in
                        completionHandler()
                    })
                    
                } else {
                    
                    self.maskImageView.stopAnimating()
                    listCell.isInTransition = false
                    listCell.animating(enable: listVC.shouldPlay)

                    completionHandler()
                }
            })
            
        } else {
            
            printLog(" can't get fromCell / toCell at \(currentIndex)")
            listView.alpha = 1
            listVC.collectionView.alpha = 1
            transitionContext.completeTransition(true)
        }        
    }
    
    public func update(with offset: CGPoint, progress: CGFloat) {
        detailView.alpha = 1 - progress
//        let translation = CGAffineTransform(translationX: offset.x, y: offset.y)
//        let scale = CGAffineTransform(scaleX: 1 - 0.2 * progress, y: 1 - 0.2 * progress)
//        maskImageView.frame = imageBeginFrame.applying(translation.concatenating(scale))
        
        let rect = CGRect(origin: imageBeginFrame.origin + offset, size: imageBeginFrame.size)
        maskImageView.frame = rect.insetBy(scale: 0.1 * progress)
    }
}

