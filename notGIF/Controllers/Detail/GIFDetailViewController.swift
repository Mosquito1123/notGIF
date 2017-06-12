//
//  GIFDetailViewController.swift
//  notGIF
//
//  Created by Atuooo on 09/10/2016.
//  Copyright © 2016 xyz. All rights reserved.
//

import UIKit
import MessageUI
import RealmSwift
import MBProgressHUD
import ReachabilitySwift
import MobileCoreServices

class GIFDetailViewController: UIViewController {
    
    public var gifList: Results<NotGIF>!
    fileprivate var notifiToken: NotificationToken?
    
    fileprivate var canPanToPop: Bool = false
    fileprivate var percentDrivenTransition: UIPercentDrivenInteractiveTransition?
    fileprivate var popAnimator: PopDetailAnimator?
    
    public var currentIndex: Int = 0 {
        didSet {
            guard currentIndex != oldValue,
                let listVC = navigationController?.viewControllers.first as? GIFListViewController else { return }
            // for pop back to cell at currentIndex
            listVC.scrollToShowCell(at: currentIndex)
        }
    }
    
    fileprivate var isBarHidden = false {
        didSet {
            shareBar.isHidden = isBarHidden
            navigationController?.setNavigationBarHidden(isBarHidden, animated: true)
        }
    }
    
    fileprivate let defaultInfo = "xxx Frames\n xx / xx"
    fileprivate lazy var titleInfoLabel: CustomLabel = {
        return CustomLabel(aFont: UIFont.menlo(ofSize: 16),
                           bFont: UIFont.menlo(ofSize: 11))
    }()

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            let layout = UICollectionViewFlowLayout()
            layout.itemSize = kScreenSize
            layout.minimumLineSpacing = 0
            layout.minimumInteritemSpacing = 0
            layout.scrollDirection = .horizontal
            
            collectionView.setCollectionViewLayout(layout, animated: true)
            collectionView.panGestureRecognizer.addTarget(self, action: #selector(panToDismissHandler(ges:)))
        }
    }
    
    fileprivate lazy var shareBar: GIFShareBar = {
        let bar = GIFShareBar()
        bar.shareHandler = { [unowned self] shareType in
            self.shareGIF(to: shareType)
        }
        return bar
    }()
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = titleInfoLabel
        setNotificationToken()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        printLog("")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.scrollToItem(at: IndexPath(item: currentIndex, section: 0), at: .left, animated: false)
    }
    
    deinit {
        printLog(" deinited ")
        notifiToken?.stop()
        notifiToken = nil
    }
}

// MARK: - UICollectionView Delegate

extension GIFDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gifList != nil ? gifList.count : 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: GIFDetailCell = collectionView.dequeueReusableCell(for: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? GIFDetailCell else { return }
        
        let gif = gifList[indexPath.item]
        cell.imageView.setGIFImage(with: gif.id, shouldPlay: true) { _ in

        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? GIFDetailCell else { return }
        cell.imageView.cancelTask()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        isBarHidden = !isBarHidden
    }
}

// MARK: - Share GIF
extension GIFDetailViewController {
    fileprivate func shareGIF(to type: ShareType) {
        GIFShareManager.shareGIF(of: gifList[currentIndex].id, to: type)
    }
}

// MARK: - UIScrollView Delegate

extension GIFDetailViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !canPanToPop {
            collectionView.alwaysBounceVertical = true
        }
        
        updateGIFInfoLabel()
    }
}

// MARK: - Navigation Delegate

extension GIFDetailViewController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if operation == .pop, toVC is GIFListViewController {
            popAnimator = PopDetailAnimator()
            popAnimator?.isTriggeredByPan = percentDrivenTransition != nil
            return popAnimator
        }
        
        return nil
    }
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        
        return percentDrivenTransition
    }
        
    func panToDismissHandler(ges: UIPanGestureRecognizer) {
        
        let velocity = ges.velocity(in: view)
        let offset = ges.translation(in: view)
        let progress = min(fabs(offset.y / (kScreenHeight * 0.4)), 1.0)
        
        switch ges.state {
            
        case .began:
            canPanToPop = fabs(velocity.y) > fabs(velocity.x)
            
            if canPanToPop {
                percentDrivenTransition = UIPercentDrivenInteractiveTransition()
                navigationController?.setNavigationBarHidden(false, animated: false)
                navigationController?.popViewController(animated: true)
                
            } else {
                collectionView.alwaysBounceVertical = false
            }
            
        case .changed:
            guard canPanToPop else { return }
            popAnimator?.update(with: offset, progress: progress)
            percentDrivenTransition?.update(progress)
            
        case .cancelled, .ended:
            guard canPanToPop else { return }

            if fabs(velocity.y) > 2000 {
                percentDrivenTransition?.update(0.9)
                percentDrivenTransition?.finish()
            } else {
                if progress > 0.4 {
                    percentDrivenTransition?.update(1.0)
                    percentDrivenTransition?.finish()
                } else {
                    percentDrivenTransition?.cancel()
                    navigationController?.setNavigationBarHidden(isBarHidden, animated: true)
                }
            }
            
            percentDrivenTransition = nil

        case .failed, .possible:
            break
        }
    }
}

// MARK: - MessageViewController Delegate

extension GIFDetailViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        DispatchQueue.main.async {
            controller.dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - Helper Method 

extension GIFDetailViewController {
    
    fileprivate func setNotificationToken() {
        guard gifList != nil else { printLog("invaild gifList result"); return }
        
        notifiToken = gifList.addNotificationBlock { [weak self] changes in
            guard let collectionView = self?.collectionView else { return }
            
            switch changes {
                
            case .initial:
                collectionView.reloadData()
                self?.updateGIFInfoLabel()
                
            case .update(_, let deletions, let insertions, let modifications):
                
                collectionView.performBatchUpdates({
                    collectionView.insertItems(at: insertions.map{ IndexPath(item: $0, section: 0) })
                    collectionView.deleteItems(at: deletions.map{ IndexPath(item: $0, section: 0) })
                    collectionView.reloadItems(at: modifications.map{ IndexPath(item: $0, section: 0) })
                }, completion: nil)
                
                self?.updateGIFInfoLabel()

            case .error(let err):
                println(err.localizedDescription)
            }
        }
    }
    
    public func showShareBarToWindow() {
        UIApplication.shared.keyWindow?.addSubview(shareBar)
        shareBar.animate()
    }
    
    public func moveShareBarToView() {
        shareBar.removeFromSuperview()
        view.addSubview(shareBar)
        view.bringSubview(toFront: shareBar)
    }
    
    fileprivate func updateGIFInfoLabel() {
        currentIndex = Int(collectionView.contentOffset.x / kScreenWidth)
        titleInfoLabel.info = NotGIFLibrary.shared.getGIFInfoStr(of: gifList[currentIndex]) ?? defaultInfo
    }
}
