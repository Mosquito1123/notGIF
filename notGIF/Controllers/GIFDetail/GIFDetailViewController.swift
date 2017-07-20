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
    
    public var isBarHidden = false {
        didSet {
            toolView.setHidden(isBarHidden, animated: true)
            navigationController?.setNavigationBarHidden(isBarHidden, animated: true)
            NotificationCenter.default.post(name: .hideStatusBar, object: isBarHidden)
        }
    }
    
    fileprivate let defaultInfo = "xxx Frames\n xx / xx"
    fileprivate lazy var titleInfoLabel: GIFInfoLabel = {
        return GIFInfoLabel(aFont: UIFont.menlo(ofSize: 16),
                            bFont: UIFont.menlo(ofSize: 11))
    }()
    
    public lazy var toolView: GIFDetailToolView = {
        return GIFDetailToolView(delegate: self)
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
        cell.imageView.setGIFImage(with: gif.id, shouldPlay: true) {  _ in

        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? GIFDetailCell else { return }
        cell.imageView.cancelTask()
        cell.imageView.stopAnimating()
        cell.imageView.resetSpeed()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        isBarHidden = !isBarHidden
    }
}

// MARK: - Tool View Delegate
extension GIFDetailViewController: GIFDetailToolViewDelegate {
    func changePlayState(playing: Bool) {
        guard let cell = collectionView.cellForItem(at: IndexPath(item: currentIndex, section: 0)) as? GIFDetailCell else { return }
        cell.animating(enable: playing)
    }
    
    func changePlaySpeed(_ speed: TimeInterval) {
        guard let cell = collectionView.cellForItem(at: IndexPath(item: currentIndex, section: 0)) as? GIFDetailCell else { return }
        cell.imageView.updateSpeed(speed)
    }
    
    func addTag() {
        
    }
    
    func removeTagOrGIF() {
        
    }
    
    func showAllFrame() {
        
    }
}

// MARK: - UIScrollView Delegate

extension GIFDetailViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !canPanToPop {
            collectionView.alwaysBounceVertical = true
        }
        
        updateGIFInfo()
    }
}

// MARK: - Transition

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
                NotificationCenter.default.post(name: .hideStatusBar, object: false)
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
                self?.updateGIFInfo()
                
            case .update(_, let deletions, let insertions, let modifications):
                
                collectionView.performBatchUpdates({
                    collectionView.insertItems(at: insertions.map{ IndexPath(item: $0, section: 0) })
                    collectionView.deleteItems(at: deletions.map{ IndexPath(item: $0, section: 0) })
                    collectionView.reloadItems(at: modifications.map{ IndexPath(item: $0, section: 0) })
                }, completion: nil)
                
                self?.updateGIFInfo()

            case .error(let err):
                println(err.localizedDescription)
            }
        }
    }
    
    fileprivate func updateGIFInfo() {
        currentIndex = Int(collectionView.contentOffset.x / kScreenWidth)
        if let gifInfo = NotGIFLibrary.shared.getGIFInfo(of: gifList[currentIndex].id) {
            titleInfoLabel.info = gifInfo.0
            toolView.reset(withSpeed: gifInfo.1)
        } else {
            titleInfoLabel.info = defaultInfo
            toolView.reset(withSpeed: 0)
        }
    }

    // for push transition
    public func showToolViewToWindow() {
        UIApplication.shared.keyWindow?.addSubview(toolView)
        toolView.animate()
    }
    
    public func moveToolViewToView() {
        view.addSubview(toolView)
        view.bringSubview(toFront: toolView)
    }
}
