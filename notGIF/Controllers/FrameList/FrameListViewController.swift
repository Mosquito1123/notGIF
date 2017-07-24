//
//  FrameListViewController.swift
//  notGIF
//
//  Created by Atuooo on 21/07/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit
import ImageIO

class FrameListViewController: UIViewController {
    public var gifID: String = ""
    
    fileprivate var imgSource: CGImageSource!
    fileprivate var frames: [UIImage] = []
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.backgroundColor = UIColor.bgColor
            
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
    
    fileprivate lazy var fecthFrameQueue: DispatchQueue = {
        return DispatchQueue(label: "notGIF-fecth-frame", qos: .userInitiated)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.titleView = titleLabel
        
        HUD.show(.requestData)
        
        fecthFrameQueue.async {
            NotGIFLibrary.shared.requestGIFData(of: self.gifID) { [weak self] gifInfo in
                guard let sSelf = self, let gifData = gifInfo?.data,
                    let gifSource = CGImageSourceCreateWithData(gifData as CFData, nil)
                    else { return }
                
                sSelf.imgSource = gifSource
                let imgCount = CGImageSourceGetCount(gifSource)
                
                let options = [kCGImageSourceCreateThumbnailFromImageAlways as String : true as NSNumber] as CFDictionary
                for i in 0 ..< imgCount {
                    if let frame = CGImageSourceCreateThumbnailAtIndex(gifSource, i, options) {
                        sSelf.frames.append(UIImage(cgImage: frame))
                    }
                }
                
                DispatchQueue.main.async {
                    sSelf.collectionView.reloadData()
                    sSelf.titleLabel.text = String.trans_titleAllFrame+"(\(imgCount))"
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
        return frames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: FrameListCell = collectionView.dequeueReusableCell(for: indexPath)
        cell.indexLabel.text = "\(indexPath.item+1)"
        cell.imageView.image = frames[indexPath.item]
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let frameDetailVC = UIStoryboard.frameDetail
        frameDetailVC.imgSource = imgSource
        frameDetailVC.imgCount = frames.count
        frameDetailVC.currentIndex = indexPath.item
        navigationController?.pushViewController(frameDetailVC, animated: true)
    }
}
