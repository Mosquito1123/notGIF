//
//  PushDetailAnimator.swift
//  notGIF
//
//  Created by ooatuoo on 2017/6/8.
//  Copyright © 2017年 xyz. All rights reserved.
//

import UIKit

fileprivate let duration = 0.5

class PushDetailAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let listVC = transitionContext.viewController(forKey: .from) as? GIFListViewController,
                let detailVC = transitionContext.viewController(forKey: .to) as? GIFDetailViewController,
                let listView = transitionContext.view(forKey: .from),
                let detailView = transitionContext.view(forKey: .to) else {
            
            transitionContext.completeTransition(true)
            return
        }
        
        let container = transitionContext.containerView
        container.insertSubview(detailView, belowSubview: listView)
                
        if let selectIP = listVC.selectIndexPath,
            let listCell = listVC.collectionView.cellForItem(at: selectIP) as? GIFListCell {
            
            let imageView: NotGIFImageView = listCell.imageView
            let imageOriginFrame = listCell.imageView.frame
            let imageBeginRect = listVC.collectionView.convert(listCell.frame, to: UIApplication.shared.keyWindow)
            let imageFinalRect = UIScreen.main.bounds
            
            listCell.isInTransition = true
            listVC.shouldPlay = false
            listCell.isHidden = true
            
            imageView.startAnimating()
            imageView.frame = imageBeginRect
            container.addSubview(imageView)

            detailView.alpha = 0

            UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 2, options: [], animations: { 
                
                listVC.collectionView.alpha = 0 
                listCell.imageView.frame = imageFinalRect
                
            }, completion: { _ in
                
                detailView.alpha = 1
                detailVC.collectionView.alpha = 1

                imageView.stopAnimating()
                let detailCell = detailVC.collectionView.cellForItem(at: selectIP) as? GIFDetailCell
                detailCell?.imageView.startAnimating()
                
                imageView.removeFromSuperview()
                imageView.frame = imageOriginFrame
                listCell.contentView.insertSubview(imageView, at: 0)
                listCell.isInTransition = false
                
                let isSuccess = !transitionContext.transitionWasCancelled
                transitionContext.completeTransition(isSuccess)
            })
            
        } else {
            detailView.alpha = 1
            transitionContext.completeTransition(true)
        }
    }
}
