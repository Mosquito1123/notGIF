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
    
    public var currentIndex: Int = 0 {
        didSet {
            guard currentIndex != oldValue,
                let listVC = navigationController?.viewControllers.first as? GIFListViewController else { return }
            // for pop back to cell at currentIndex
            listVC.scrollToShowCell(at: currentIndex)
        }
    }
    
    fileprivate var notifiToken: NotificationToken?
    
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
    
    fileprivate lazy var infoLabel = GIFInfoLabel()
    
    fileprivate var gifLibrary = NotGIFLibrary.shared
    
    fileprivate var percentDrivenTransition: UIPercentDrivenInteractiveTransition?
    fileprivate var popAnimator: PopDetailAnimator?
    
    fileprivate var isBarHidden = false {
        didSet {
            shareBar.isHidden = isBarHidden
            navigationController?.setNavigationBarHidden(isBarHidden, animated: true)
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
        
        navigationItem.titleView = infoLabel
        setNotificationToken()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.delegate = self
        view.addSubview(shareBar)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.scrollToItem(at: IndexPath(item: currentIndex, section: 0), at: .left, animated: false)
    }
    
    func updateUI() {
        func updateInfoLabel() {
            currentIndex = Int(collectionView.contentOffset.x / kScreenWidth)
            //            infoLabel.info = gifLibrary[currentIndex]?.gifInfo ?? tmpInfo
        }
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            updateInfoLabel()
        }
        
        collectionView.reloadData()
        CATransaction.commit()
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
        cell.imageView.setGIFImage(with: gif.id, shouldPlay: true) {[weak self] gif in
            self?.infoLabel.info = gif.info
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
        switch type {
            
        case .twitter, .weibo:
            if let reachability = Reachability(), reachability.isReachable {
                if let gifInfo = gifLibrary.getDataInfo(at: currentIndex) {
                    let composeVC = ComposeViewController(shareType: type, with: gifInfo)
                    composeVC.modalPresentationStyle = .overCurrentContext
                    present(composeVC, animated: true, completion: nil)
                } else {
                    StatusBarToast.shared.show(info: .once(message: "unavailable data, try again", succeed: false))
                }
                
            } else {
                ATAlert.alert(type: .noInternet, in: self, withDismissAction: nil)
            }
            
        case .wechat:
            if OpenShare.canOpen(platform: .wechat) {
                if let gifInfo = gifLibrary.getDataInfo(at: currentIndex) {
                    OpenShare.shareGIF(to: .wechat, with: gifInfo)
                } else {
                    StatusBarToast.shared.show(info: .once(message: "unavailable data, try again", succeed: false))
                }
            } else {
                ATAlert.alert(type: .noApp("Wechat"), in: self, withDismissAction: nil)
            }
            
        case .more:
            
//            MBProgressHUD.showAdded(to: view, with: "Preparing")
            
            NotGIFLibrary.shared.requestGIFData(at: currentIndex) { data in
                if let gifData = data {
                    let activityVC = UIActivityViewController(activityItems: [gifData], applicationActivities: nil)
                    DispatchQueue.main.async {
                        self.present(activityVC, animated: true, completion: nil)
                        MBProgressHUD.hide(for: self.view, animated: true)
                    }
                } else {
//                    MBProgressHUD.hide(for: self.view, animated: true)
                    StatusBarToast.shared.show(info: .once(message: "unavailable data, try again", succeed: false))
                }
            }
            
        case .message:
            
            if MFMessageComposeViewController.canSendAttachments() &&
                MFMessageComposeViewController.isSupportedAttachmentUTI(kUTTypeGIF as String) {
                
//                MBProgressHUD.showAdded(to: view, with: "Prepareing")
                
                NotGIFLibrary.shared.requestGIFData(at: currentIndex) { data in
                    
                    if let gifData = data {
                        
                        let messageVC = MFMessageComposeViewController()
                        messageVC.messageComposeDelegate = self
                        messageVC.addAttachmentData(gifData, typeIdentifier: kUTTypeGIF as String, filename: "not.gif")
                        DispatchQueue.main.async {
                            self.present(messageVC, animated: true, completion: nil)
                            MBProgressHUD.hide(for: self.view, animated: true)
                        }
                        
                    } else {
//                        MBProgressHUD.hide(for: self.view, animated: true)
                        StatusBarToast.shared.show(info: .once(message: "unavailable data, try again", succeed: false))
                    }
                }
            }
        }
    }
}

// MARK: - UIScrollView Delegate

extension GIFDetailViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        currentIndex = Int(scrollView.contentOffset.x / kScreenWidth)
//        infoLabel.info = gifLibrary[currentIndex]?.gifInfo ?? tmpInfo
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
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        printLog("")
//        guard let toVC = viewController as? GIFListViewController else { return }
//        toVC.shouldPlay = true
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        printLog("")
    }
    
    func panToDismissHandler(ges: UIPanGestureRecognizer) {
        
        let velocity = ges.velocity(in: view)
        let offset = ges.translation(in: view)
        let progress = min(fabs(offset.y / (kScreenHeight * 0.4)), 1.0)
        
        switch ges.state {
        case .began:
            
            let canPanToPop = fabs(velocity.y) > fabs(velocity.x)
            
            if canPanToPop {
                percentDrivenTransition = UIPercentDrivenInteractiveTransition()
                navigationController?.setNavigationBarHidden(false, animated: false)
                navigationController?.popViewController(animated: true)
                
            } else {
                collectionView.alwaysBounceVertical = false
            }
            
        case .changed:
            
            popAnimator?.update(with: offset, progress: progress)
            percentDrivenTransition?.update(progress)
            
        case .cancelled, .ended:
            
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
            collectionView.alwaysBounceVertical = true
            
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
                
            case .update(_, let deletions, let insertions, let modifications):
                
                collectionView.performBatchUpdates({
                    collectionView.insertItems(at: insertions.map{ IndexPath(item: $0, section: 0) })
                    collectionView.deleteItems(at: deletions.map{ IndexPath(item: $0, section: 0) })
                    collectionView.reloadItems(at: modifications.map{ IndexPath(item: $0, section: 0) })
                }, completion: nil)
                
            case .error(let err):
                println(err.localizedDescription)
            }
        }
    }
}
