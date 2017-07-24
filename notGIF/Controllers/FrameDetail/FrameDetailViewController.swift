//
//  FrameDetailViewController.swift
//  notGIF
//
//  Created by Atuooo on 21/07/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit
import ImageIO
import Photos
import MobileCoreServices

class FrameDetailViewController: UIViewController {
    public var imgSource: CGImageSource!
    public var imgCount: Int = 0
    public var currentIndex: Int = 0 {
        didSet {
            titleLabel.text = "\(currentIndex+1) / \(imgCount)"
        }
    }
    
    fileprivate var isBarHidden: Bool = false {
        didSet {
            guard isBarHidden != oldValue else { return }
            navigationController?.setNavigationBarHidden(isBarHidden, animated: true)
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    fileprivate let spacing: CGFloat = 30
    fileprivate lazy var collectionLayout: FrameDetailLayout = {
        return FrameDetailLayout(size: kScreenSize, spacing: self.spacing)
    }()
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.setCollectionViewLayout(collectionLayout, animated: true)
            collectionView.decelerationRate = UIScrollViewDecelerationRateFast
            collectionView.backgroundColor = UIColor.bgColor
        }
    }
    
    fileprivate lazy var titleLabel: NavigationTitleLabel = {
        return NavigationTitleLabel()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.titleView = titleLabel
        navigationController?.navigationBar.tintColor = UIColor.textTint
        
        collectionView.scrollToItem(at: IndexPath(row: currentIndex, section: 0), at: .left, animated: false)
    }
    
    override var prefersStatusBarHidden: Bool {
        return isBarHidden
    }
    
    deinit {
        printLog("deinited")
    }
}

// MARK: - CollectionView Delegate
extension FrameDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imgCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: FrameDetailCell = collectionView.dequeueReusableCell(for: indexPath)
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? FrameDetailCell,
                let frame = CGImageSourceCreateImageAtIndex(imgSource, indexPath.item, nil) else { return }
        
        cell.configureWith(UIImage(cgImage: frame))
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? FrameDetailCell else { return }
        cell.reset()
    }
}

// MARK: - Cell Delegate
extension FrameDetailViewController: FrameDetailCellDelegate {
    func didBeginZoom() {
        isBarHidden = true
    }
    
    func didLongPress() {
        Alert.show(.saveImage, in: self) {
            self.saveCurrentIndexImage()
        }
    }
    
    func didTap() {
        isBarHidden = !isBarHidden
    }
}

// MARK: - ScrollView Delegate
extension FrameDetailViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        currentIndex = Int(scrollView.contentOffset.x / (kScreenWidth+spacing))
    }
}

// MARK: - Helper Method
extension FrameDetailViewController {
    fileprivate func saveCurrentIndexImage() {
        guard let frame = CGImageSourceCreateImageAtIndex(imgSource, currentIndex, nil),
            let pngData = UIImagePNGRepresentation(UIImage(cgImage: frame)),
            let image = UIImage(data: pngData) else { return }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { (success, error) in
            if success {
                DispatchQueue.main.async {
                    HUD.show(text: String.trans_titleSaveSuccess, delay: 2.0)
                }
            }
        }
    }
}
