//
//  MessagesViewController.swift
//  notGIFMessage
//
//  Created by Atuooo on 23/10/2016.
//  Copyright © 2016 xyz. All rights reserved.
//

import UIKit
import Photos
import Messages
import RealmSwift

fileprivate var theContext: Void?

class MessagesViewController: MSMessagesAppViewController {
    
    fileprivate var allTag: Tag?
    fileprivate var gifList: Results<NotGIF>!
    fileprivate var notifiToken: NotificationToken?
    fileprivate var couldShowList: Bool = false
    
    // speed control
    fileprivate lazy var lastDate = Date()
    fileprivate var lastOffsetY: CGFloat = 0
    fileprivate var controlSpeed: TimeInterval?
    fileprivate var playSpeed: PlaySpeedInList = NGUserDefaults.playSpeedInList
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            let layout = UICollectionViewFlowLayout()
            layout.minimumInteritemSpacing = 1
            layout.minimumLineSpacing = 1
            layout.sectionInset = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
            layout.footerReferenceSize = CGSize(width: kScreenWidth, height: GIFListFooter.height)
            layout.itemSize = CGSize(width: (kScreenWidth - 4) / 3, height: (kScreenWidth - 4) / 3)
            collectionView.setCollectionViewLayout(layout, animated: true)
            
            collectionView.registerFooterOf(GIFListFooter.self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareRealm()
        prepareGIFLibrary()
        
        NotGIFLibrary.shared.stateChangeHandler = { [weak self] state in
            DispatchQueue.main.async {
                self?.updateUI(with: state)
            }
        }
        
        updateUI(with: NotGIFLibrary.shared.state)
    }
    
    // MARK: - Fetch GIF
    
    fileprivate func showAllGIF() {
        guard let realm = try? Realm() else { return }
        
        gifList = realm.objects(NotGIF.self).sorted(byKeyPath: "creationDate", ascending: false)
        allTag = realm.object(ofType: Tag.self, forPrimaryKey: Config.defaultTagID)
        
        notifiToken = gifList.addNotificationBlock { [weak self] changes in
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
                
            case .error(let err):
                print(err.localizedDescription)
            }
        }
    }
    
    fileprivate func updateUI(with state: NotGIFLibraryState) {
        switch state {
            
        case .preparing:
            HUD.show(to: collectionView, .fetchGIF)
            
        case .fetchDone:
            HUD.hide(in: collectionView)
            showAllGIF()
            
        case .accessDenied, .error:
            HUD.hide(in: self.collectionView)
            collectionView.reloadData()
        }
    }
}

// MARK: - UICollectionView Delegate 

extension MessagesViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (gifList == nil || !couldShowList) ? 0 : gifList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: MGIFListViewCell = collectionView.dequeueReusableCell(for: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        guard let cell = cell as? MGIFListViewCell else { return }
        
        let speed = playSpeed == .normal ? controlSpeed : playSpeed.value
        cell.imageView.setGIFImage(with: gifList[indexPath.item].id, shouldPlay: true) {
            _ in
            cell.imageView.updateSpeed(speed)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? MGIFListViewCell else { return }
        cell.imageView.cancelTask()
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let footer: GIFListFooter = collectionView.dequeueReusableFooter(for: indexPath)
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        if authorizationStatus != .notDetermined {
            let type: GIFListFooterType = authorizationStatus == .authorized ? .showCount(allTag) : .needAuthorize
            footer.update(with: type)
        }
        
        return footer
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let conversation = activeConversation,
            let asset = NotGIFLibrary.shared.getAsset(with: gifList[indexPath.item].id) else { return }
        
        asset.requestContentEditingInput(with: PHContentEditingInputRequestOptions()) { (eidtingInput, info) in
            if let input = eidtingInput, let gifURL = input.fullSizeImageURL {
                conversation.insertAttachment(gifURL, withAlternateFilename: nil) { error in
                    
                }
                
                if self.presentationStyle == .expanded {
                    self.requestPresentationStyle(.compact)
                }
            }
        }
    }
}

extension MessagesViewController: UIScrollViewDelegate {
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
                .flatMap { $0 as? MGIFListViewCell }
                .forEach { $0.imageView.updateSpeed(nil) }
        }
    }
}
