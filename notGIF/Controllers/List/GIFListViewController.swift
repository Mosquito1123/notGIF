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

class GIFListViewController: UIViewController {
    
    public var gifList: Results<NotGIF>!
    public var selectIndexPath: IndexPath?
    
    public var shouldPlay: Bool {
        set { _shouldPlay = !manualPaused && newValue }
        get { return _shouldPlay }
    }
    
    fileprivate var _shouldPlay: Bool = true {
        didSet {
            guard _shouldPlay !=  oldValue else { return }
            
            collectionView.visibleCells
            .flatMap { $0 as? GIFListCell }
            .forEach { $0.animating(enable: _shouldPlay) }
        }
    }
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.registerFooterOf(GIFListFooter.self)
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
    
    fileprivate var notifiToken: NotificationToken?
    
    fileprivate var currentTag: Tag?
    fileprivate var manualPaused = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setToolbarHidden(true, animated: false)
        
        navigationItem.titleView = titleLabel
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .pause,
                                                            target: self,
                                                            action: #selector(autoplayItemClicked))
        navigationItem.rightBarButtonItem?.tintColor = .gray
        
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            DispatchQueue.main.safeAsync {
                
                HUD.show(.fetchGIF)
                
                NotGIFLibrary.shared.prepare(completion: { (lastTag, needBgUpdate) in
                    self.showGIFList(of: lastTag)
                    HUD.hide()
                    
                    if needBgUpdate {
                        
                    }
                }, bgUpdateCompletion: {
                    
                })
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(GIFListViewController.checkToUpdateGIFList(with:)), name: .didSelectTag, object: nil)
        
        #if DEBUG
            view.addSubview(FPSLabel())
        #endif
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setDrawerPanGes(enable: true)

        selectIndexPath = nil
        // fix delegate
        navigationController?.delegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        
        switch identifier {
        case "showDetail":
            guard let detailVC = segue.destination as? GIFDetailViewController,
                    let selectIP = sender as? IndexPath else { return }
            detailVC.currentIndex = selectIP.item
            detailVC.gifList = gifList
            
        case "showAddTag":
            guard let popover = segue.destination.popoverPresentationController else { return }
            popover.sourceView = view
            popover.sourceRect = view.bounds
            popover.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
            popover.delegate = self
            
        default:
            break
        }
    }
    
    deinit {
        notifiToken?.stop()
        notifiToken = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    func autoplayItemClicked() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: shouldPlay ? .play : .pause, target: self, action: #selector(autoplayItemClicked))
        navigationItem.rightBarButtonItem?.tintColor = .gray
        manualPaused = shouldPlay
        shouldPlay = !shouldPlay
    }
}

// MARK: - Collection Delegate
extension GIFListViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            return gifList != nil ? gifList.count : 0
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: GIFListCell = collectionView.dequeueReusableCell(for: indexPath)
        
        cell.shareGIFHandler = { [weak self] type in
            guard let sSelf = self, let shareIP = collectionView.indexPath(for: cell) else { return }
            
            if type == .tag {
                sSelf.beginAddTag()
                
            } else {
                let gifID = sSelf.gifList[shareIP.item].id
                GIFShareManager.shareGIF(of: gifID, to: type)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? GIFListCell else { return }
                
        cell.imageView.setGIFImage(with: gifList[indexPath.item].id, shouldPlay: shouldPlay) { gif in
            cell.timeLabel.text = gif.totalDelayTime.timeStr
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? GIFListCell else { return }
        cell.imageView.cancelTask()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        defer {
            collectionView.deselectItem(at: indexPath, animated: true)
        }
        
        guard selectIndexPath == nil else { return }
        selectIndexPath = indexPath
        performSegue(withIdentifier: "showDetail", sender: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let footer: GIFListFooter = collectionView.dequeueReusableFooter(for: indexPath)
        let type: GIFListFooterType = PHPhotoLibrary.authorizationStatus() == .authorized ? .showCount(currentTag) : .needAuthorize
        footer.update(with: type)
        return footer
    }
}

// MARK: - Add Tag 

extension GIFListViewController {
    
    fileprivate func beginAddTag() {
        navigationController?.setToolbarHidden(false, animated: true)
    }
}

// MARK: - CollectionLayout Delegate

extension GIFListViewController: GIFListLayoutDelegate {
    
    func ratioForImageAtIndexPath(indexPath: IndexPath) -> CGFloat {
        return gifList[indexPath.item].ratio
    }
}

// MARK: - Navigation Delegate

extension GIFListViewController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if operation == .push, toVC is GIFDetailViewController {
            return PushDetailAnimator()
        }
        
        return nil
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        setDrawerPanGes(enable: false)
    }
}

// MARK: - Popover Delegate

extension GIFListViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return false
    }
}

// MARK: - Notification Handler 

extension GIFListViewController {
    
    func checkToUpdateGIFList(with noti: Notification) {
        guard let selectTag = noti.object as? Tag, selectTag.id != currentTag?.id
            else { return }
        
        NGUserDefaults.lastSelectTagID = selectTag.id
        showGIFList(of: selectTag)
    }
}

// MARK: - Helper Method

extension GIFListViewController {
    
    fileprivate func showGIFList(of tag: Tag?) {
        guard let tag = tag else { return }
        
        notifiToken?.stop()
        notifiToken = nil
                    
        currentTag = tag
        gifList = tag.gifs.sorted(byKeyPath: "creationDate", ascending: false)
        
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
    
    fileprivate func setDrawerPanGes(enable: Bool) {
        guard let drawer = navigationController?.parent as? DrawerViewController else {
            fatalError("----- can't get drawer to disable pan ges -----")
        }
        
        drawer.sidePanGes.isEnabled = enable
    }
    
    public func scrollToShowCell(at index: Int) {
        if let lastSelectIP = selectIndexPath {
            collectionView.cellForItem(at: lastSelectIP)?.isHidden = false
        }
        
        let toShowIP = IndexPath(item: index, section: 0)
        collectionView.scrollToItem(at: toShowIP, at: .centeredVertically, animated: false)
        collectionView.reloadItems(at: [toShowIP])
    }
}



