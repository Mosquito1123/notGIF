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

typealias GIFDataInfo = (data: Data, thumbnail: UIImage)

public typealias GIFRetrieveCompletion = (_ image: NotGIFImage, _ localID: String, _ withTransition: Bool) -> ()

@objc enum NotGIFLibraryState: Int {
    case startBgUpdate = 1
    case fetchDoneFromPhotos
    case bgUpdateDone
    case accessDenied
    case preparing
}

class NotGIFLibrary: NSObject {
    
    static let shared = NotGIFLibrary()
    
    dynamic var stateStatus: Int = NotGIFLibraryState.preparing.rawValue
    
    fileprivate var state: NotGIFLibraryState = .preparing {
        willSet { stateStatus = newValue.rawValue }
    }
    
    fileprivate lazy var gifPool: [String: NotGIFImage] = [:]
    fileprivate lazy var gifAssetPool: [String: PHAsset] = [:]
    
    fileprivate lazy var allImageFetchResult: PHFetchResult<PHAsset> = {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return PHAsset.fetchAssets(with: .image, options: fetchOptions)
    }()
    
    fileprivate lazy var bgFetchQueue: DispatchQueue = {    // TODO: - Concurrent
        return DispatchQueue(label: "com.notGIF.bgFetch", qos: .utility)
    }()
    
    fileprivate lazy var queuePool: DispatchQueuePool = {
        return DispatchQueuePool(name: "com.notGIF.getGIF", qos: .utility, queueCount: 6)
    }()
        
    public func prepare() {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else { return }
        
        do {
            let realm = try Realm()
            
            if NGUserDefaults.haveFetched { // 直接从 Realm 中获取 GIF 信息
                
                let notGIFs = realm.objects(NotGIF.self)
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
                
                state = .startBgUpdate
                
                // 后台更新 GIF Library
                bgFetchQueue.async { [weak self] in
                    self?.updateGIFLibrary(with: Set<PHAsset>(tempAllGIFAessts))
                    self?.state = .bgUpdateDone
                }
                
            } else {     // 从 Photos 中获取 GIF
                
                let allGIFAssets = fetchAllGIFAssetsFromPhotos()
                let defaultTag = realm.object(ofType: Tag.self, forPrimaryKey: Config.defaultTagID)
                
                realm.beginWrite()
                
                allGIFAssets.forEach {
                    gifAssetPool[$0.localIdentifier] = $0
                    let notGIF = NotGIF(asset: $0)
                    realm.add(notGIF, update: true)
                    defaultTag?.gifs.append(notGIF)
                }
                
                try? realm.commitWrite()
                
                state = .fetchDoneFromPhotos
                
                NGUserDefaults.haveFetched = true
            }
            
        } catch let err {
            printLog("init Realm failed:\n\(err.localizedDescription)")
        }
    }
    
    fileprivate func fetchAllGIFAssetsFromPhotos() -> Set<PHAsset> {
        var assetSet = Set<PHAsset>()
        
        allImageFetchResult.enumerateObjects(options: .concurrent, using: {(asset, _, _) in
            if asset.isGIF {
                assetSet.insert(asset)
            }
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
    
    public func getAsset(with assetID: String) -> PHAsset? {
        if let asset = gifAssetPool[assetID] {
            return asset
        } else {
            return PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil).firstObject
        }
    }
        
    public func getGIFInfoStr(of gif: NotGIF) -> String? {
        return gifPool[gif.id]?.info ?? nil
    }
    
    // retrieve gif to show
    public func retrieveGIF(with id: String, completionHandler: @escaping GIFRetrieveCompletion) -> DispatchWorkItem? {
        
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
                                                          resultHandler: { [weak self] (data, UTI, _, _) in
                                                            
                    if let uti = UTI, UTTypeConformsTo(uti as CFString, kUTTypeGIF),
                        let gifData = data, let gif = NotGIFImage(gifData: gifData) {
                        
                        self?.gifPool[id] = gif
                        completionHandler(gif, id, true)
                    }
                })
            })
            
            queuePool.queue.async(execute: workItem)
            return workItem
        }
    }
    
    // request data to share gif
    public func requestGIFData(of gifID: String, completionHandler: @escaping (GIFDataInfo?) -> Void) {
        guard let gifAsset = gifAssetPool[gifID], let gif = gifPool[gifID] else {
            completionHandler(nil)
            return
        }
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.version = .unadjusted
        
        PHImageManager.default().requestImageData(for: gifAsset, options: requestOptions) { (gifData, _, _, _) in
            
            if let gifData = gifData {
                completionHandler((gifData, gif.posterImage))
            } else {
                completionHandler(nil)
            }
        }
    }
    
    // MARK: - Init
    
    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)

        if PHPhotoLibrary.authorizationStatus() == .denied {
            state = .accessDenied
        }
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
}

// MARK: - PhotoLibrary Delegate

extension NotGIFLibrary: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        guard let changes = changeInstance.changeDetails(for: allImageFetchResult),
            changes.hasIncrementalChanges else { return }
        
        allImageFetchResult = changes.fetchResultAfterChanges
        
        let removedGIFIDs  = changes.removedObjects.filter { $0.isGIF }.map { $0.localIdentifier }
        let insertedGIFAssets = changes.insertedObjects.filter { $0.isGIF }
        
        guard !removedGIFIDs.isEmpty || !insertedGIFAssets.isEmpty,
            let realm = try? Realm() else { return }
        
        state = .startBgUpdate
        
        let toDeleteGIFs = realm.objects(NotGIF.self).filter{ removedGIFIDs.contains($0.id) }
        removedGIFIDs.forEach { gifID in
            gifAssetPool.removeValue(forKey: gifID)
            gifPool.removeValue(forKey: gifID)
        }
        
        var toInsertGIFs = [NotGIF]()
        insertedGIFAssets.forEach {
            gifAssetPool[$0.localIdentifier] = $0
            toInsertGIFs.append(NotGIF(asset: $0))
        }
        
        try? realm.write {
            realm.delete(toDeleteGIFs)
            realm.add(toInsertGIFs, update: true)
            
            if let defaultTag = realm.object(ofType: Tag.self, forPrimaryKey: Config.defaultTagID) {
                defaultTag.gifs.append(objectsIn: toInsertGIFs)
            }
        }
        
        state = .bgUpdateDone
    }
}

public func prepareGIFLibrary() {
    DispatchQueue.global().async {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                NotGIFLibrary.shared.state = .accessDenied
                return
            }
    
            let queue = DispatchQueue(label: "prepareGIF", qos: .userInitiated, attributes: [])
            queue.async {
                NotGIFLibrary.shared.prepare()
            }
        }
    }
}
