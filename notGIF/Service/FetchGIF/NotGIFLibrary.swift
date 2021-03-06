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
    case preparing
    case fetchDone
    case accessDenied
    case error
}

class NotGIFLibrary: NSObject {
    
    static let shared = NotGIFLibrary()
    
    public var stateChangeHandler: ((NotGIFLibraryState) -> Void)?
    
    public var state: NotGIFLibraryState = .preparing {
        didSet {
            stateChangeHandler?(state)
        }
    }
    
    /// 用来存储所获取的 NotGIFImage
    fileprivate lazy var gifPool: [String: NotGIFImage] = [:]
    
    /// 用来存储 GIF 的 Asset
    fileprivate lazy var gifAssetPool: [String: PHAsset] = [:]
    
    /// 相册中所有 Image 的 PHFetchResult
    fileprivate lazy var allImageFetchResult: PHFetchResult<PHAsset> = {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return PHAsset.fetchAssets(with: .image, options: fetchOptions)
    }()
    
    /// 异步更新 GIF Library 的队列
    fileprivate lazy var bgFetchQueue: DispatchQueue = {    // TODO: - Concurrent
        return DispatchQueue(label: "com.notGIF.bgFetch", qos: .utility)
    }()
    
    /// 获取 NotGIFImage 的串行队列池
    fileprivate lazy var queuePool: DispatchQueuePool = {
        return DispatchQueuePool(name: "com.notGIF.getGIF", qos: .utility, queueCount: 6)
    }()
    
    /// 准备 GIF Library
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
                
                state = .fetchDone
                
                // 后台更新 GIF Library
                bgFetchQueue.async { [weak self] in
                    self?.updateGIFLibrary(with: Set<PHAsset>(tempAllGIFAessts))
                }
                
            } else {     // 从 Photos 中获取 GIF
                NGUserDefaults.shouldAutoPlay = true  // 默认自动播放

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
                
                state = .fetchDone
                NGUserDefaults.haveFetched = true
            }
            
        } catch let err {
            state = .error
            printLog("init Realm failed: \n\(err.localizedDescription)")
        }
    }
    
    /// 更新 GIF Library (后台异步)
    /// - Parameter tempGIFAssetSet: 当前 GIFAsset 的集合
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
    
    /// 获取 NotGIFImage
    ///
    /// - Parameters:
    ///   - id: GIF id
    ///   - completionHandler: 当成功获取 或 初始化 NotGIFImage 时调用
    /// - Returns: 获取 Image 的 DispatchWorkItem，当不再需要展示时用来取消任务项
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
    
    /// 获取 GIF 元数据
    ///
    /// - Parameters:
    ///   - gifID:  GIF id
    ///   - completionHandler: 返回 (data: Data, thumbnail: UIImage)?
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
    
    // MARK: - Helper Methods
    
    /// 从相册中获取所有 GIF 资源
    /// - Returns: GIF 的 Asset 集合
    fileprivate func fetchAllGIFAssetsFromPhotos() -> Set<PHAsset> {
        var assetSet = Set<PHAsset>()
        
        allImageFetchResult.enumerateObjects(options: .concurrent, using: {(asset, _, _) in
            if asset.isGIF {
                assetSet.insert(asset)
            }
        })
        
        return assetSet
    }
    
    /// 根据 assetID 获取 Asset
    ///
    /// - Parameter assetID: localIdentifier
    /// - Returns: GIF 的 Asset
    public func getAsset(with assetID: String) -> PHAsset? {
        if let asset = gifAssetPool[assetID] {
            return asset
        } else {
            return PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil).firstObject
        }
    }
    
    /// 获取 GIF 信息
    ///
    /// - Parameter gif: GIF ID
    /// - Returns: infoStr：帧数+时间+大小; averageSpeed: 平均速度
    public func getGIFInfo(of gifID: String) -> (String, TimeInterval)? {
        guard let gifImage = gifPool[gifID] else { return nil }
        let infoStr = gifImage.info
        let averageSpeed = gifImage.totalDelayTime / TimeInterval(gifImage.frameCount)
        return (infoStr, averageSpeed)
    }
    
    public subscript(gifID: String) -> NotGIFImage? {
        return gifPool[gifID]
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
    }
}

// MARK: - Public Prepare GIF
public func prepareGIFLibrary() {
    setDefaultActions()
    
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

/// 设置默认的动作列表
fileprivate func setDefaultActions() {
    if !NGUserDefaults.haveSetDefaultActions {
        NGUserDefaults.customActions = GIFActionType.defaultActions
        NGUserDefaults.haveSetDefaultActions = true
    }
}

// MARK: - PHAsset
extension PHAsset {
    var isGIF: Bool {
        guard let assetSource = PHAssetResource.assetResources(for: self).first else {
            return false
        }
        
        let uti = assetSource.uniformTypeIdentifier as CFString
        return UTTypeConformsTo(uti, kUTTypeGIF)
    }
}
