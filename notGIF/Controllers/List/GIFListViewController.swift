//
//  GIFListViewController.swift
//  notGIF
//
//  Created by Atuooo on 09/10/2016.
//  Copyright © 2016 xyz. All rights reserved.
//

import UIKit
import Photos
import RealmSwift
import MBProgressHUD

private let cellID = "GIFListCell"

class GIFListViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    fileprivate var indicatorView: IndicatorView? {
        willSet {
            indicatorView?.removeFromSuperview()
        }
    }
    
    fileprivate lazy var titleLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        label.text = "/jif/"
        label.font = UIFont.kenia(ofSize: 26)
        label.textColor = .textTint
        label.textAlignment = .center
        return label
    }()
    
    @IBAction func sideBarItemClicked(_ sender: UIBarButtonItem) {
        if let drawer = navigationController?.parent as? DrawerViewController {
            drawer.showOrDissmissSideBar()
        }
    }
    
    fileprivate var gifList: Results<NotGIF>!
    fileprivate var notifiToken: NotificationToken?
    
    fileprivate var currentTag: Tag!
    fileprivate var hasPaused = false
    
    fileprivate var shouldPlay = true {
        didSet {
            if shouldPlay != oldValue {
                for cell in collectionView.visibleCells {
                    if let cell = cell as? GIFListViewCell {
                        shouldPlay ? cell.imageView.startAnimating() : cell.imageView.stopAnimating()
                    }
                }
            }
        }
    }
    
    var selectedFrame = CGRect.zero
    var selectedImage: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.titleView = titleLabel
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(autoplayItemClicked))
        navigationItem.rightBarButtonItem?.tintColor = .gray
        
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            DispatchQueue.main.safeAsync {
                
                HUD.show(text: "fetching GIFs...")
                
                NotGIFLibrary.shared.prepare { lastSelectTag in
                    self.showGIFList(of: lastSelectTag)
                    HUD.hide()
                }
            }
        }
        
        #if DEBUG
            view.addSubview(FPSLabel())
        #endif
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !hasPaused {
            shouldPlay = true
        }
        
        navigationController?.delegate = self
    }
    
    public func showGIFList(of tag: Tag?) {
        guard let tag = tag else { return }
        
        notifiToken?.stop()
        notifiToken = nil
        
        currentTag = tag
        gifList = tag.gifs.sorted(byKeyPath: "creationDate", ascending: true)
        
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
                print(err.localizedDescription)
            }
        }
    }
    
    deinit {
        notifiToken?.stop()
        notifiToken = nil
    }
    
    func autoplayItemClicked() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: shouldPlay ? .play : .pause, target: self, action: #selector(autoplayItemClicked))
        navigationItem.rightBarButtonItem?.tintColor = .gray
        hasPaused = shouldPlay
        shouldPlay = !shouldPlay
    }
}

extension GIFListViewController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if operation == .push, toVC is GIFDetailViewController {
            let pushAnimator = PushDetailAnimator()
            selectedFrame = collectionView.convert(selectedFrame, to: UIApplication.shared.keyWindow)
            pushAnimator.fromRect = selectedFrame
            pushAnimator.transitionImage = selectedImage
            
            return pushAnimator
        }
        
        return nil
    }
}

// MARK: - Collection Delegate
extension GIFListViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gifList != nil ? gifList.count : 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! GIFListViewCell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        guard let cell = cell as? GIFListViewCell else { return }
        cell.imageView.setGIFImage(with: gifList[indexPath.item].id, shouldPlay: shouldPlay)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? GIFListViewCell else { return }
        cell.imageView.cancelTask()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? GIFListViewCell {
            
            selectedFrame = cell.frame
            selectedImage = cell.imageView.currentFrame
            
            let detailVC = GIFDetailViewController()
            detailVC.currentIndex = indexPath.item
            shouldPlay = false
            
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}

// MARK: - GIFListLayout Delegate
extension GIFListViewController: GIFListLayoutDelegate {
    
    func ratioForImageAtIndexPath(indexPath: IndexPath) -> CGFloat {
        return gifList[indexPath.item].ratio
    }
}
