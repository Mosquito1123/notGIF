//
//  NotGIFLibrary.swift
//  notGIF
//
//  Created by Atuooo on 09/10/2016.
//  Copyright © 2016 xyz. All rights reserved.
//

import Photos
import ImageIO
import Foundation
import MobileCoreServices

typealias GIFDataInfo = (asset: PHAsset, thumbnail: UIImage)

protocol NotGIFLibraryChangeObserver: NSObjectProtocol {
    func gifLibraryDidChange()
}

class NotGIFLibrary: NSObject {
    static let shared = NotGIFLibrary()
    weak var observer: NotGIFLibraryChangeObserver?

    var gifAssets = [PHAsset]()

    var count: Int {
        return gifAssets.count
    }
    
    var isEmpty: Bool {
        return gifAssets.isEmpty
    }
    
    var authorizationStatus: PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus()
    }
    
    subscript(index: Int) -> NotGIFImage? {
        if index >= count {
            return nil
        } else {
            return gifPool[gifAssets[index].localIdentifier]
        } 
    }
    
    fileprivate var hasFetched = false
    fileprivate var gifPool = [String: NotGIFImage]()
    
    fileprivate lazy var fetchResult: PHFetchResult<PHAsset> = {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return PHAsset.fetchAssets(with: .image, options: fetchOptions)
    }()
    
    func prepare() {
        if !hasFetched {
            hasFetched = true

            if let gifIDs = UserDefaults.standard.array(forKey: gifIDs_Key) as? [String] {
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                let fetchedAssets = PHAsset.fetchAssets(withLocalIdentifiers: gifIDs, options: fetchOptions)
                gifAssets = fetchedAssets.objects(at: IndexSet(integersIn: 0..<fetchedAssets.count))
                
                let queue = DispatchQueue(label: "com.atuo.notgif.backgroud_fetch", qos: .background)
                queue.async { [weak self] in
                    guard let sSelf = self else { return }
                    let assets = sSelf.fetchGIFAssets()
                    let newIDs = assets.map { $0.localIdentifier }
                    if gifIDs != newIDs {
                        sSelf.saveGIFIDsFrom(assets)
                        sSelf.gifAssets = assets
                        sSelf.observer?.gifLibraryDidChange()
                    }
                }
                
            } else {
                
                gifAssets = fetchGIFAssets()
                saveGIFIDsFrom(gifAssets)
            }
        }
    }
    
    fileprivate func fetchGIFAssets() -> [PHAsset] {
        var idIndexSet = IndexSet()
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        
        fetchResult.enumerateObjects(options: .concurrent,
                                        using: {(asset, index, _) in
            
            PHImageManager.default().requestImageData(for: asset,
                                                  options: requestOptions,
                                            resultHandler: {(_, UTI, _, _) in
                if let uti = UTI,
                    UTTypeConformsTo(uti as CFString, kUTTypeGIF) {
                    idIndexSet.insert(index)
                }
            })
        })
        
        return fetchResult.objects(at: idIndexSet)
    }
    
    fileprivate func saveGIFIDsFrom(_ assets: [PHAsset]) {
        let gifIDs = assets.map { $0.localIdentifier }
        UserDefaults.standard.set(gifIDs, forKey: gifIDs_Key)
        UserDefaults.standard.synchronize()
    }
    
    func getDataInfo(at index: Int) -> GIFDataInfo? {
        let asset = gifAssets[index]
        
        if let gif = gifPool[asset.localIdentifier] {
            return (asset, gif.thumbnail)
        } else {
            return nil
        }
    }
    
    func requestGIFData(at index: Int, resultHandler: @escaping (Data?) -> Void) {
        let gifAsset = gifAssets[index]
        PHImageManager.requestGIFData(for: gifAsset) { data in
            resultHandler(data)
        }
    }
    
    func getGIFImage(at index: Int, doneHandler: @escaping (NotGIFImage) -> Void) {
        let gifKey = gifAssets[index].localIdentifier
        
        if let gif = gifPool[gifKey] {
            doneHandler(gif)
        } else {
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = false
            requestOptions.version = .original
            
            PHImageManager.default()
                .requestImageData(for: gifAssets[index],
                                  options: requestOptions)
            { (data, UTI, orientation, info) in
                
                if let uti = UTI, UTTypeConformsTo(uti as CFString , kUTTypeGIF),
                    let gifData = data, let gif = NotGIFImage(data: gifData) {
                    
                    self.gifPool[gifKey] = gif
                    doneHandler(gif)
                }
            }
        }
    }
    
    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
}

extension NotGIFLibrary: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        guard let changes = changeInstance.changeDetails(for: fetchResult)
            else { return }
        
        if changes.hasIncrementalChanges {
            
            fetchResult = changes.fetchResultAfterChanges
            let removedGIF = changes.removedObjects.filter { $0.isGIF }
            let insertedGIF = changes.insertedObjects.filter { $0.isGIF }
            
            if !removedGIF.isEmpty || !insertedGIF.isEmpty {    // curt
                
                removedGIF.forEach({
                    gifAssets.remove(object: $0)
                    gifPool.removeValue(forKey: $0.localIdentifier)
                })
                
                insertedGIF.forEach {
                    gifAssets.append($0)
                }
                
                gifAssets.sort { assetA, assetB in
                    guard let dateA = assetA.creationDate,
                        let dateB = assetB.creationDate else { return false }
                    return dateA > dateB
                }
                saveGIFIDsFrom(gifAssets)
                observer?.gifLibraryDidChange()
            }
        }
    }
}

extension PHAsset {
    var ratio: CGFloat {
        return CGFloat(pixelWidth) / CGFloat(pixelHeight)
    }
    
    var isGIF: Bool {
        guard let assetSource = PHAssetResource.assetResources(for: self).first else {
            return false
        }
        
        let uti = assetSource.uniformTypeIdentifier as CFString
        return UTTypeConformsTo(uti, kUTTypeGIF) || assetSource.originalFilename.hasSuffix("GIF")
    }
}

extension PHImageManager {
    class open func requestGIFData(for asset: PHAsset, resultHandler: @escaping (Data?) -> Void) {
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.version = .original
        
        PHImageManager.default()
            .requestImageData(for: asset,
                          options: requestOptions)
        { (data, UTI, orientation, info) in
            
            if let gifData = data, let uti = UTI, UTTypeConformsTo(uti as CFString , kUTTypeGIF) {
                resultHandler(gifData)
            } else {
                resultHandler(data)
            }
        }
    }
}
