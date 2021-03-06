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
import StoreKit
import RealmSwift
import MBProgressHUD

fileprivate var theContext: Void?

class GIFListViewController: UIViewController {
    
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
    
    // data source
    fileprivate var currentTag: Tag?
    fileprivate var gifResults: Results<NotGIF>!
    fileprivate var notifiToken: NotificationToken?
    fileprivate var couldShowList: Bool = false
    
    // speed control
    fileprivate lazy var lastDate = Date()
    fileprivate var lastOffsetY: CGFloat = 0
    fileprivate var controlSpeed: TimeInterval?
    fileprivate var playSpeed: PlaySpeedInList = NGUserDefaults.playSpeedInList
    
    // edit tag
    fileprivate var isEditingGIFsTag: Bool = false
    fileprivate var selectGIFIPs: Set<IndexPath> = [] {
        didSet {
            chooseCountItem.title = "\(selectGIFIPs.count) GIF"
            addTagItem.isEnabled = !selectGIFIPs.isEmpty
            removeTagItem.isEnabled = !selectGIFIPs.isEmpty
        }
    }
    
    // subviews
    @IBOutlet weak var addTagItem: UIBarButtonItem!
    @IBOutlet weak var removeTagItem: UIBarButtonItem!
    
    @IBOutlet weak var chooseCountItem: UIBarButtonItem! {
        didSet {
            chooseCountItem.setTitleTextAttributes([NSFontAttributeName: UIFont.menlo(ofSize: 17)], for: .normal)
        }
    }
    
    fileprivate lazy var playControlItem: UIBarButtonItem = {
        let conrolButton = PlayControlButton(showPlay: self.manualPaused) { isPaused in
            self.manualPaused = isPaused
            NGUserDefaults.shouldAutoPlay = !isPaused
        }
        return UIBarButtonItem(customView: conrolButton)
    }()
    
    fileprivate lazy var cancelEditItem: UIBarButtonItem = {
        let buttonItem = UIBarButtonItem(title: String.trans_titleCancel, style: .plain, target: self, action: #selector(GIFListViewController.endEditGIFsTag(noReload:)))
        let font = UIFont.localized(ofSize: 17)
        buttonItem.setTitleTextAttributes([NSFontAttributeName: font], for: .normal)
        buttonItem.tintColor = UIColor.textTint
        return buttonItem
    }()
    
    fileprivate lazy var titleLabel: NavigationTitleLabel = {
        return NavigationTitleLabel(title: self.lastSelectTag?.localNameStr)
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
        
        // set UI
        view.backgroundColor = UIColor.commonBg
        
        navigationItem.titleView = titleLabel
        
        navigationController?.setToolbarHidden(true, animated: false)
        navigationController?.toolbar.isHidden = true
        
        manualPaused = !NGUserDefaults.shouldAutoPlay
        navigationItem.rightBarButtonItem = playControlItem
        
        // observe data source
        NotGIFLibrary.shared.stateChangeHandler = { [weak self] state in
            DispatchQueue.main.async {
                self?.updateUI(with: state)
            }
        }
        
        updateUI(with: NotGIFLibrary.shared.state)
        
        // add obersver
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(checkToUpdateGIFList(with:)),
                                               name: .didSelectTag,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updatePlaySpeed(with:)),
                                               name: .playSpeedChanged,
                                               object: nil)
        
        #if DEBUG
            view.addSubview(FPSLabel())
        #endif
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setDrawerPanGes(enable: true)

        selectIndexPath = nil
        navigationController?.delegate = self
        
        #if !DEBUG
            if #available(iOS 10.3, *) {
                SKStoreReviewController.requestReview()
            } else {
                // Fallback on earlier versions
            }
        #endif
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        
        switch identifier {
        case "showDetail":
            guard let detailVC = segue.destination as? GIFDetailViewController,
                    let selectIP = sender as? IndexPath else { return }
            detailVC.currentIndex = selectIP.item
            detailVC.gifResults = gifResults
            
        case "showAddTag":
            guard let addTagVC = (segue.destination as? UINavigationController)?.topViewController as? PopoverTagListViewController ,
                    let popover = segue.destination.popoverPresentationController else { return }
            
            addTagVC.toAddGIFs = sender as! [NotGIF]
            addTagVC.addGIFTagCompletion = { [weak self] in
                self?.endEditGIFsTag(noReload: false)
            }
            
            popover.sourceView = view
            popover.sourceRect = view.bounds
            popover.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
            popover.delegate = self
            
        case "showFrameList":
            guard let nav = segue.destination as? UINavigationController,
                let frameListVC = nav.topViewController as? FrameListViewController else { return }
            
            frameListVC.gifID = sender as! String
            
        default:
            fatalError("undefined identifier: \(identifier)")
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
        
        let selectGIFs = selectGIFIPs.map{ gifResults[$0.item] }
        performSegue(withIdentifier: "showAddTag", sender: selectGIFs)
    }
    
    @IBAction func removeTagItemClicked(_ sender: UIBarButtonItem) {
        guard !selectGIFIPs.isEmpty else { return }
        
        if currentTag?.id == Config.defaultTagID {
            Alert.show(.confirmDeleteGIF(selectGIFIPs.count), in: self) {
                self.deleteChoosedGIF()
            }
        } else {
            Alert.show(.confirmRemoveGIF(selectGIFIPs.count, currentTag?.localNameStr ?? ""), in: self) {
                self.removeChoosedGIF()
            }
        }
    }
}

// MARK: - Edit Tag

extension GIFListViewController {
    
    fileprivate func beginEditGIFsTag(from beginIP: IndexPath) {
        let cell = collectionView.cellForItem(at: beginIP) as? GIFListCell
        cell?.setChoosed(true, animate: true)
        
        isEditingGIFsTag = true
        selectGIFIPs.insert(beginIP)
        shouldPlay = false
        
        removeTagItem.image = currentTag?.id == Config.defaultTagID ? #imageLiteral(resourceName: "icon_delete_gif") : #imageLiteral(resourceName: "icon_remove_tag")
        navigationItem.rightBarButtonItem = cancelEditItem
        navigationController?.toolbar.isHidden = false
        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    @objc fileprivate func endEditGIFsTag(noReload: Bool) {
        isEditingGIFsTag = false
        navigationItem.rightBarButtonItem = playControlItem
        navigationController?.setToolbarHidden(true, animated: true)
        navigationController?.toolbar.isHidden = true
        
        shouldPlay = true
        selectGIFIPs.removeAll()
        
        if !noReload {
            collectionView.reloadData()
        }
    }
    
    fileprivate func removeChoosedGIF() {
        let gifs = selectGIFIPs.map{ gifResults[$0.item] }
        
        try? Realm().write {
            currentTag?.gifs.remove(objectsIn: gifs)
        }
        
        endEditGIFsTag(noReload: true)
        updateFooter()
    }
    
    fileprivate func deleteChoosedGIF() {
        let assetIDs = selectGIFIPs.map { gifResults[$0.item].id }
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: assetIDs, options: nil)
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assets)
        }, completionHandler: { (isSuccess, _) in
            DispatchQueue.main.async {
                self.endEditGIFsTag(noReload: isSuccess)
            }
        })
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
    
    func updatePlaySpeed(with noti: Notification) {
        guard let newSpeed = noti.object as? PlaySpeedInList,
                playSpeed != newSpeed else { return }
        
        playSpeed = newSpeed
        collectionView.visibleCells
            .flatMap { $0 as? GIFListCell }
            .forEach { $0.imageView.updateSpeed(newSpeed.value) }
    }
}

// MARK: - Collection Delegate
extension GIFListViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            return (gifResults == nil || !couldShowList) ? 0 : gifResults.count
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: GIFListCell = collectionView.dequeueReusableCell(for: indexPath)
        
        cell.actionHandler = { [weak self] type in
            guard let sSelf = self, let cellIP = collectionView.indexPath(for: cell) else { return }
            
            switch type {
            case .shareTo(let sType):
                let gifID = sSelf.gifResults[cellIP.item].id
                GIFShareManager.shareGIF(of: gifID, to: sType)
                
            case .editTag:
                sSelf.beginEditGIFsTag(from: cellIP)
                
            case .showAllFrame:
                sSelf.performSegue(withIdentifier: "showFrameList", sender: sSelf.gifResults[cellIP.item].id)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? GIFListCell else { return }
        let speed = playSpeed == .normal ? controlSpeed : playSpeed.value
        
        cell.setChoosed(selectGIFIPs.contains(indexPath), animate: false)
        cell.imageView.setGIFImage(with: gifResults[indexPath.item].id, shouldPlay: shouldPlay) { gif in
            cell.imageView.updateSpeed(speed)
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
        
        guard let cell = collectionView.cellForItem(at: indexPath) as? GIFListCell,
                cell.imageView.animateImage != nil else { return }
        
        if isEditingGIFsTag {
            if selectGIFIPs.contains(indexPath) {
                selectGIFIPs.remove(indexPath)
                cell.setChoosed(false, animate: true)
            } else {
                selectGIFIPs.insert(indexPath)
                cell.setChoosed(true, animate: true)
            }
            
        } else {
            guard selectIndexPath == nil else { return }
            selectIndexPath = indexPath
            performSegue(withIdentifier: "showDetail", sender: indexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let footer: GIFListFooter = collectionView.dequeueReusableFooter(for: indexPath)
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        if authorizationStatus != .notDetermined {
            let type: GIFListFooterType = authorizationStatus == .authorized ? .showCount(currentTag) : .needAuthorize
            footer.update(with: type)
        }
        
        return footer
    }
}

// MARK: - CollectionLayout Delegate

extension GIFListViewController: GIFListLayoutDelegate {
    
    func ratioForImageAtIndexPath(indexPath: IndexPath) -> CGFloat {
        return gifResults[indexPath.item].ratio
    }
}

// MARK: - Transition

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

// MARK: - ScrollView Delegate
extension GIFListViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard playSpeed == .normal else { return }
        
        let currentDate = Date()
        let dateDiff = currentDate.timeIntervalSince(lastDate)
        let offsetDiff = scrollView.contentOffset.y - lastOffsetY
        
        lastDate = currentDate
        lastOffsetY = scrollView.contentOffset.y
        
        let speed = offsetDiff/CGFloat(dateDiff)

        if fabs(speed) > 80 {
            controlSpeed = 0.2
        } else {
            guard controlSpeed != nil else { return }
            controlSpeed = nil
            collectionView.visibleCells
                .flatMap { $0 as? GIFListCell }
                .forEach { $0.imageView.updateSpeed(nil) }
        }
    }
}

// MARK: - Helper Method

extension GIFListViewController {
    
    fileprivate func showGIFList(of tag: Tag? = nil) {
        let theTag = tag ?? lastSelectTag
        guard let tag = theTag, tag.id != currentTag?.id else { return }
        
        titleLabel.text = tag.localNameStr
        titleLabel.sizeToFit()
        
        notifiToken?.stop()
        notifiToken = nil
                    
        currentTag = tag
        gifResults = tag.gifs.sorted(byKeyPath: "creationDate", ascending: false)
        
        // observe gif list
        notifiToken = gifResults.addNotificationBlock { [weak self] changes in
            guard let collectionView = self?.collectionView else { return }
            switch changes {
                
            case .initial:
                self?.couldShowList = true
                collectionView.reloadData()
                
            case .update(_, let deletions, let insertions, let modifications):
                
                collectionView.performBatchUpdates({
                    collectionView.insertItems(at: insertions.map{ IndexPath(item: $0, section: 0) })
                    collectionView.deleteItems(at: deletions.map{ IndexPath(item: $0, section: 0) })
                    collectionView.reloadItems(at: modifications.map{ IndexPath(item: $0, section: 0) })
                }, completion: nil)
                
                self?.updateFooter()
            
            case .error(let err):
                println(err.localizedDescription)
            }
        }
    }
    
    fileprivate var lastSelectTag: Tag? {
        guard let realm = try? Realm() else { return nil }
        
        if let lastSelectTag = realm.object(ofType: Tag.self, forPrimaryKey: NGUserDefaults.lastSelectTagID) {
            return lastSelectTag
            
        } else {
            let defaultTag = realm.object(ofType: Tag.self, forPrimaryKey: Config.defaultTagID)
            NGUserDefaults.lastSelectTagID = Config.defaultTagID
            return defaultTag
        }
    }
    
    fileprivate func updateUI(with state: NotGIFLibraryState) {
        switch state {
            
        case .preparing:
            HUD.show(to: navigationController?.view, .fetchGIF)
            
        case .fetchDone:
            HUD.hide(in: navigationController?.view)
            showGIFList()
            
        case .accessDenied, .error:
            HUD.hide(in: navigationController?.view)
            collectionView.reloadData()
        }
    }
    
    fileprivate func updateFooter() {
        guard let footerIP = collectionView.indexPathsForVisibleSupplementaryElements(ofKind: UICollectionElementKindSectionFooter).first,
            let footer = collectionView.supplementaryView(forElementKind: UICollectionElementKindSectionFooter, at: footerIP) as? GIFListFooter
        else { return }
        
        footer.update(with: .showCount(currentTag))
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
            collectionView.reloadItems(at: [lastSelectIP])
            selectIndexPath = nil
        }
        
        let toShowIP = IndexPath(item: index, section: 0)
        collectionView.scrollToItem(at: toShowIP, at: .centeredVertically, animated: false)
        collectionView.reloadItems(at: [toShowIP])
    }
}



