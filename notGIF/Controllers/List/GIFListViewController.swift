//
//  GIFListViewController.swift
//  notGIF
//
//  Created by Atuooo on 09/10/2016.
//  Copyright © 2016 xyz. All rights reserved.
//

import UIKit
import Photos
import SnapKit
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
    
    fileprivate var manualPaused = false {
        didSet { shouldPlay = !manualPaused }
    }
    
    fileprivate var currentTag: Tag?
    fileprivate var notifiToken: NotificationToken?
    
    fileprivate var isEditingGIFsTag: Bool = false
    fileprivate var selectGIFIPs: Set<IndexPath> = [] {
        didSet {
            chooseCountItem.title = "\(selectGIFIPs.count) GIF"
            addTagItem.isEnabled = !selectGIFIPs.isEmpty
            removeTagItem.isEnabled = currentTag?.id != Config.defaultTagID && !selectGIFIPs.isEmpty
        }
    }
    
    @IBOutlet weak var addTagItem: UIBarButtonItem!
    @IBOutlet weak var removeTagItem: UIBarButtonItem!
    
    @IBOutlet weak var chooseCountItem: UIBarButtonItem! {
        didSet {
            chooseCountItem.setTitleTextAttributes([NSFontAttributeName: UIFont.menlo(ofSize: 17)], for: .normal)
        }
    }
    
    fileprivate lazy var playControlItem: UIBarButtonItem = {
        let conrolButton = PlayControlButton(showPlay: self.manualPaused) { showPlay in
            self.manualPaused = showPlay
            NGUserDefaults.shouldAutoPause = showPlay
        }
        return UIBarButtonItem(customView: conrolButton)
    }()
    
    fileprivate lazy var cancalEditGIFTagItem: UIBarButtonItem = {
        let buttonItem = UIBarButtonItem(title: String.trans_titleCancel, style: .plain, target: self, action: #selector(GIFListViewController.endEditGIFsTag(noReload:)))
        let font = Config.isChinese ? UIFont.systemFont(ofSize: 17, weight: 20) : UIFont.menlo(ofSize: 17)
        buttonItem.setTitleTextAttributes([NSFontAttributeName: font], for: .normal)
        buttonItem.tintColor = UIColor.textTint
        return buttonItem
    }()
    
    fileprivate lazy var titleView: LoadingTitleView = {
        return LoadingTitleView()
    }()
    
    fileprivate lazy var sloganView: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "slogan"))
        imageView.frame = CGRect(x: 0, y: -90, width: kScreenWidth, height: 40)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor.lightGray
        return imageView
    }()
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.registerFooterOf(GIFListFooter.self)
            collectionView.addSubview(sloganView)
        }
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !NGUserDefaults.haveShowIntro {
            performSegue(withIdentifier: "showIntro", sender: nil)
        }
        
        navigationItem.titleView = titleView
        navigationController?.setToolbarHidden(true, animated: false)
        
        manualPaused = NGUserDefaults.shouldAutoPause
        navigationItem.rightBarButtonItem = playControlItem
        
        let hudView = navigationController?.view
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            DispatchQueue.main.async {
                HUD.show(to: hudView, .fetchGIF)

                NotGIFLibrary.shared.prepare(completion: { (lastTag, needBgUpdate) in
                    HUD.hide(in: hudView)
                    self.showGIFList(of: lastTag)
                    if needBgUpdate { self.titleView.update(isLoading: true) }
                    
                }, bgUpdateCompletion: {
                    self.titleView.update(isLoading: false)
                })
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(GIFListViewController.checkToUpdateGIFList(with:)), name: .didSelectTag, object: nil)
        
        #if DEBUG
//            view.addSubview(FPSLabel())
        #endif
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setDrawerPanGes(enable: true)

        selectIndexPath = nil
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
            guard let addTagVC = (segue.destination as? UINavigationController)?.topViewController as? AddTagListViewController ,
                    let popover = segue.destination.popoverPresentationController else { return }
            
            addTagVC.fromTag = currentTag
            addTagVC.toAddGIFs = sender as! [NotGIF]
            addTagVC.addGIFTagCompletion = { [weak self] in
                self?.endEditGIFsTag(noReload: false)
            }
            
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
    
    // MARK: - Button/Item Action
    
    @IBAction func sideBarItemClicked(_ sender: UIBarButtonItem) {
        if let drawer = navigationController?.parent as? DrawerViewController {
            drawer.showOrDissmissSideBar()
        }
    }
    
    @IBAction func addTagItemClicked(_ sender: UIBarButtonItem) {
        guard !selectGIFIPs.isEmpty else { return }
        
        let selectGIFs = selectGIFIPs.map{ gifList[$0.item] }
        performSegue(withIdentifier: "showAddTag", sender: selectGIFs)
    }
    
    @IBAction func removeTagItemClicked(_ sender: UIBarButtonItem) {
        guard !selectGIFIPs.isEmpty else { return }
        
        Alert.show(.confirmRemoveGIF(selectGIFIPs.count, currentTag?.localNameStr ?? ""), in: self) {
            self.removeChoosedGIF()
        }
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
        cell.update(isChoosed: selectGIFIPs.contains(indexPath), animate: false)
        
        cell.shareGIFHandler = { [weak self] type in
            guard let sSelf = self, let cellIP = collectionView.indexPath(for: cell) else { return }
            
            if type == .tag {
                sSelf.beginEditGIFsTag(from: cellIP)
                
            } else {
                let gifID = sSelf.gifList[cellIP.item].id
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
        cell.imageView.stopAnimating()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        defer {
            collectionView.deselectItem(at: indexPath, animated: true)
        }
        
        if isEditingGIFsTag {
            guard let cell = collectionView.cellForItem(at: indexPath) as? GIFListCell else { return }
            
            if selectGIFIPs.contains(indexPath) {
                selectGIFIPs.remove(indexPath)
                cell.update(isChoosed: false, animate: true)
            } else {
                selectGIFIPs.insert(indexPath)
                cell.update(isChoosed: true, animate: true)
            }
            
        } else {
            guard selectIndexPath == nil else { return }
            selectIndexPath = indexPath
            performSegue(withIdentifier: "showDetail", sender: indexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let footer: GIFListFooter = collectionView.dequeueReusableFooter(for: indexPath)
        let type: GIFListFooterType = PHPhotoLibrary.authorizationStatus() == .authorized ? .showCount(currentTag) : .needAuthorize
        footer.update(with: type)
        return footer
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
        guard let selectTag = noti.object as? Tag else { return }
        
        if let currentTag = currentTag, !currentTag.isInvalidated, currentTag.id == selectTag.id {
            return
        }
        
        if isEditingGIFsTag {
            endEditGIFsTag(noReload: false)
        }
        
        NGUserDefaults.lastSelectTagID = selectTag.id
        showGIFList(of: selectTag)
    }
}


// MARK: - Edit Tag

extension GIFListViewController {
    
    fileprivate func beginEditGIFsTag(from beginIP: IndexPath) {
        let cell = collectionView.cellForItem(at: beginIP) as? GIFListCell
        cell?.update(isChoosed: true, animate: true)
        
        isEditingGIFsTag = true
        selectGIFIPs.insert(beginIP)
        shouldPlay = false
        
        removeTagItem.isEnabled = currentTag?.id != Config.defaultTagID
        navigationItem.rightBarButtonItem = cancalEditGIFTagItem
        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    @objc fileprivate func endEditGIFsTag(noReload: Bool) {
        isEditingGIFsTag = false
        navigationItem.rightBarButtonItem = playControlItem
        navigationController?.setToolbarHidden(true, animated: true)
        
        shouldPlay = true
        selectGIFIPs.removeAll()
        
        if !noReload {
            collectionView.reloadData()
        }
    }
    
    fileprivate func removeChoosedGIF() {
        let gifs = selectGIFIPs.map{ gifList[$0.item] }
                
        try? Realm().write {
            currentTag?.gifs.remove(objectsIn: gifs)
        }

        endEditGIFsTag(noReload: true)
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



