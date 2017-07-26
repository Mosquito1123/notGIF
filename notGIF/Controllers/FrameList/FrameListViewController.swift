//
//  FrameListViewController.swift
//  notGIF
//
//  Created by Atuooo on 21/07/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit
import ImageIO

fileprivate let initFetchCount: Int = 20

class FrameListViewController: UIViewController {
    public var gifID: String = ""
    
    fileprivate var imgSource: CGImageSource!
    fileprivate var imgCount: Int = 0
    fileprivate var framePool: [Int: UIImage] = [:]
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.backgroundColor = UIColor.commonBg
            
            let layout = UICollectionViewFlowLayout()
            layout.minimumInteritemSpacing = 1
            layout.minimumLineSpacing = 1
            layout.sectionInset = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
            layout.itemSize = CGSize(width: (kScreenWidth - 4) / 3, height: (kScreenWidth - 4) / 3)
            collectionView.setCollectionViewLayout(layout, animated: true)
        }
    }
    
    fileprivate lazy var titleLabel: NavigationTitleLabel = {
        return NavigationTitleLabel(title: String.trans_titleAllFrame)
    }()
    
    fileprivate lazy var fetchQueue: DispatchQueue = {
        return DispatchQueue(label: "notGIF-fecth-frame", qos: .userInitiated)
    }()
    
    fileprivate lazy var fetchOptions: CFDictionary = {
        return [
            kCGImageSourceCreateThumbnailFromImageIfAbsent as String : true as NSNumber,
            kCGImageSourceThumbnailMaxPixelSize as String : kScreenWidth/2 as NSNumber
        ] as CFDictionary
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.titleView = titleLabel
        
        HUD.show(.requestData)
        
        fetchQueue.async {
            NotGIFLibrary.shared.requestGIFData(of: self.gifID) { [weak self] gifInfo in
                guard let sSelf = self, let gifData = gifInfo?.data,
                    let gifSource = CGImageSourceCreateWithData(gifData as CFData, nil)
                    else { return }
                
                sSelf.imgSource = gifSource
                sSelf.imgCount = CGImageSourceGetCount(gifSource)
                
                for i in 0..<min(sSelf.imgCount, initFetchCount) {
                    if let frame = CGImageSourceCreateThumbnailAtIndex(gifSource, i, sSelf.fetchOptions) {
                        sSelf.framePool[i] = UIImage(cgImage: frame)
                    }
                }
                
                DispatchQueue.main.async {
                    sSelf.collectionView.reloadData()
                    sSelf.titleLabel.text = String.trans_titleAllFrame+"(\(sSelf.imgCount))"
                    HUD.hide()
                }
            }
        }
    }
    
    deinit {
        printLog("deinited")
    }
    
    @IBAction func dismissItemClicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension FrameListViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imgCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: FrameListCell = collectionView.dequeueReusableCell(for: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? FrameListCell else { return }
        
        cell.indexLabel.text = "\(indexPath.item+1)"
        
        if let frame = framePool[indexPath.item] {
            cell.imageView.image = frame
        } else {
            fetchQueue.async { [weak self] in
                guard let sSelf = self else { return }
                if let cgImage = CGImageSourceCreateThumbnailAtIndex(sSelf.imgSource, indexPath.item, sSelf.fetchOptions) {
                    let frame = UIImage(cgImage: cgImage)
                    sSelf.framePool[indexPath.item] = frame
                    DispatchQueue.main.async {
                        cell.imageView.image = frame
                    }
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let frameDetailVC = UIStoryboard.frameDetail
        frameDetailVC.imgSource = imgSource
        frameDetailVC.imgCount = imgCount
        frameDetailVC.currentIndex = indexPath.item
        navigationController?.pushViewController(frameDetailVC, animated: true)
    }
}
