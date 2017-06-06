//
//  NotGIFLibrary.swift
//  notGIF
//
//  Created by Atuooo on 09/10/2016.
//  Copyright © 2016 xyz. All rights reserved.
//

import Photos
import ImageIO
import RealmSwift
import MobileCoreServices

typealias GIFDataInfo = (asset: PHAsset, thumbnail: UIImage)

protocol NotGIFLibraryChangeObserver: NSObjectProtocol {
    func gifLibraryDidChange()
}

public typealias CompletionHandler = (_ image: NotGIFImage, _ localID: String, _ withTransition: Bool) -> ()

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
    fileprivate lazy var gifPool: [String: NotGIFImage] = [:]
    fileprivate lazy var gifAssetPool: [String: PHAsset] = [:]
    
    fileprivate lazy var allImageFetchResult: PHFetchResult<PHAsset> = {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return PHAsset.fetchAssets(with: .image, options: fetchOptions)
    }()
    
    fileprivate lazy var bgFetchQueue: DispatchQueue = {
        //TODO:- group concurrent queue for performance
        return DispatchQueue(label: "com.notGIF.bgFetch", qos: .background)
    }()
    
    fileprivate lazy var queuePool: DispatchQueuePool = {   // to use more kernel
        return DispatchQueuePool(name: "com.notGIF.getGIF", qos: .utility, queueCount: 6)
    }()
    
    func prepare(completion: @escaping ((Tag?) -> Void)) {
        guard let realm = try? Realm() else { return }
        
        let completionHandler = {
            let selectTag = realm.object(ofType: Tag.self, forPrimaryKey: NGUserDefaults.lastSelectTadID)
            completion(selectTag)
        }
        
        if NGUserDefaults.haveFetched { // 直接从 Realm 中获取 GIF 信息
            
            let notGIFs = realm.objects(NotGIF.self).sorted(byKeyPath: "creationDate", ascending: false)
            let gifIDs: [String] = notGIFs.map { $0.id }
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: gifIDs, options: nil)
            let tempAllGIFAessts = fetchResult.objects(at: IndexSet(integersIn: 0..<fetchResult.count))
            
            tempAllGIFAessts.forEach {
                gifAssetPool[$0.localIdentifier] = $0
            }
        
            let tmpAllGIFIDs = tempAllGIFAessts.map { $0.localIdentifier }
            
            // 移除 已经从相册中删除的 GIF 的对象
            try? realm.write {
                realm.delete( notGIFs.filter { !tmpAllGIFIDs.contains($0.id) } )
            }
            
            completionHandler()
            
            // 后台更新 GIF Library
            bgFetchQueue.async { [unowned self] in
                self.updateGIFLibrary(with: Set<PHAsset>(tempAllGIFAessts))
            }

        } else {    // 从 Photos 中获取 GIF
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

            allImageFetchResult = PHAsset.fetchAssets(with: fetchOptions)
            
            // TODO: - multithread
            let allGIFAssets = fetchAllGIFAssetsFromPhotos()
            let defaultTag = Tag(id: Config.defaultTagID, name: "所有")
            
            realm.beginWrite()
            
            realm.add(defaultTag, update: true)
            
            allGIFAssets.forEach {
                gifAssetPool[$0.localIdentifier] = $0
                let notGIF = NotGIF(asset: $0)
                realm.add(notGIF)
                defaultTag.gifs.append(notGIF)
            }
            
            try? realm.commitWrite()
            
            if authorizationStatus == .authorized {
                NGUserDefaults.haveFetched = true
            }
            
            completionHandler()
        }
    }
    
    fileprivate func fetchGIFAssets() -> [PHAsset] {
        var idIndexSet = IndexSet()
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        
        allImageFetchResult.enumerateObjects(options: .concurrent,
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
        
        return allImageFetchResult.objects(at: idIndexSet)
    }
    
    fileprivate func fetchAllGIFAssetsFromPhotos() -> Set<PHAsset> {
        var assetSet = Set<PHAsset>()

        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        
        allImageFetchResult.enumerateObjects(options: .concurrent,
                                     using: {(asset, index, _) in
                                        
            PHImageManager.default() .requestImageData(for: asset,
                                                       options: requestOptions,
                                                       resultHandler: {(_, UTI, _, _) in
                                                        
                if let uti = UTI, UTTypeConformsTo(uti as CFString, kUTTypeGIF) {
                    assetSet.insert(asset)
                }
            })
        })
        
        return assetSet
    }
    
    fileprivate func updateGIFLibrary(with tempGIFAssetSet: Set<PHAsset>) {
        guard let realm = try? Realm() else { return }
        
        let allGIFAssetSet = fetchAllGIFAssetsFromPhotos()
        
        let toDeleteGIFIDs = tempGIFAssetSet.subtracting(allGIFAssetSet)
                                            .map { $0.localIdentifier }
        let toInsertAssetSet = allGIFAssetSet.subtracting(tempGIFAssetSet)

        realm.beginWrite()
        
        if !toDeleteGIFIDs.isEmpty {
            toDeleteGIFIDs.forEach { gifAssetPool.removeValue(forKey: $0) }
            realm.delete( realm.objects(NotGIF.self).filter{ toDeleteGIFIDs.contains($0.id) })
        }
        
        if !toInsertAssetSet.isEmpty {
            var newNotGIFs = [NotGIF]()
            let defaultTag = realm.object(ofType: Tag.self, forPrimaryKey: Config.defaultTagID)
            
            toInsertAssetSet.forEach {
                gifAssetPool[$0.localIdentifier] = $0
                newNotGIFs.append(NotGIF(asset: $0))
            }
            
            realm.add(newNotGIFs, update: true)
            defaultTag?.gifs.append(objectsIn: newNotGIFs)
        }
        
        try? realm.commitWrite()
    }
    
    fileprivate func saveGIFIDsFrom(_ assets: [PHAsset]) {
        let gifIDs = assets.map { $0.localIdentifier }
        UserDefaults.standard.set(gifIDs, forKey: gifIDs_Key)
        UserDefaults.standard.synchronize()
    }
    
    func getDataInfo(at index: Int) -> GIFDataInfo? {
        let asset = gifAssets[index]
        
        if let gif = gifPool[asset.localIdentifier] {
            return (asset, gif.posterImage)
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

    public func retrieveGIF(with id: String, completionHandler: @escaping CompletionHandler) -> DispatchWorkItem? {
        
        if let gif = gifPool[id] {
            completionHandler(gif, id, false)
            return nil
            
        } else {
            guard let gifAsset = gifAssetPool[id] else { return nil }
            
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            requestOptions.version = .unadjusted
            
            let workItem = DispatchWorkItem(flags: [.inheritQoS, .detached], block: { 
                PHImageManager.default().requestImageData(for: gifAsset,
                                                          options: requestOptions,
                                                          resultHandler: { [unowned self] (data, UTI, _, _) in
                                                            
                    if let uti = UTI, UTTypeConformsTo(uti as CFString, kUTTypeGIF),
                        let gifData = data, let gif = NotGIFImage(gifData: gifData) {
                        
                        self.gifPool[id] = gif
                        completionHandler(gif, id, true)
                    }
                })
            })
            
            queuePool.queue.async(execute: workItem)
            return workItem 
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
        
        guard let changes = changeInstance.changeDetails(for: allImageFetchResult) else { return }
        print("photo library did change")
        
//        guard let changes = changeInstance.changeDetails(for: allImageFetchResult)
//            else { return }
//        
//        if changes.hasIncrementalChanges {
//            
//            allImageFetchResult = changes.fetchResultAfterChanges
//            let removedGIF = changes.removedObjects.filter { $0.isGIF }
//            let insertedGIF = changes.insertedObjects.filter { $0.isGIF }
//            
//            if !removedGIF.isEmpty || !insertedGIF.isEmpty {    // curt
//                
//                removedGIF.forEach({
//                    gifAssets.remove(object: $0)
//                    gifPool.removeValue(forKey: $0.localIdentifier)
//                })
//                
//                insertedGIF.forEach {
//                    gifAssets.append($0)
//                }
//                
//                gifAssets.sort { assetA, assetB in
//                    guard let dateA = assetA.creationDate,
//                        let dateB = assetB.creationDate else { return false }
//                    return dateA > dateB
//                }
//                saveGIFIDsFrom(gifAssets)
//                observer?.gifLibraryDidChange()
//            }
//        }
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
