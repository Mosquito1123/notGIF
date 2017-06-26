//
//  NotGIFImage.swift
//  notGIF
//
//  Created by ooatuoo on 2017/5/13.
//  Copyright © 2017年 xyz. All rights reserved.
//
//  The NotGIFImage and NotGIFImageView is a modified Swift version of
//  some classes from Flipboard's FLAnimatedImage project (https://github.com/Flipboard/FLAnimatedImage)

import UIKit
import ImageIO
import CoreGraphics
import MobileCoreServices

// 每帧的最小间隔不得小于 0.03s（大多数浏览器的做法 ☞ http://nullsleep.tumblr.com/post/16524517190/animated-gif-minimum-frame-delay-browser-compatibility)
public let kGIFDelayTimeIntervalMinium: TimeInterval = 0.03

// 默认间隔（当获取不到间隔时间时）
private let kGIFDelayTimeIntervalDefault: TimeInterval = 0.1
private let MEGABYTE = 1024 * 1024

private enum GIFDataSizeType: Int {
    case small = 10      // 缓存所有帧 <2.5MB
    case normal = 75     // 尽可能的提高性能
    case large = 250     // 每次只缓存一帧 (10MB)
    case unsupported     // 太大了，一帧都受不了
}

private enum CacheSizeOption: Int {
    case noLimit = 0            // sizeType == .small
    case lowMemory = 1          // sizeType == .large
    case `default` = 5          // sizeType == .normal
    
    case afterMemoryWarning = 2 // 处理完内存警告后提高缓存帧数
}

public class NotGIFImage: NSObject {
    // 最近的 ImageView 展示停止后的 index
    public var currentIndexForContinue: Int = 0
    
    // gif info
    public var frameCount = 0
    public var posterImage: UIImage!
    public var delayTimesForIndexes: Dictionary<Int, TimeInterval>!
    public var size: CGSize!
    
    public var totalDelayTime: TimeInterval = 0
    public var fileSize = 0
    
    public var info: String {
        return "\(frameCount) Frames\n"
                + totalDelayTime.timeStr + "s" + " / "
                + fileSize.byteStr
    }

    // cache option
    private var frameCacheSizeMax: Int = 0
    
    private var frameCacheSizeOptimal: Int = 0
    private var isPredrawingEnabled: Bool = true
    private var serialQueue: DispatchQueue!
    
    // cache frame
    private var posterImageFrameIndex: Int!
    
    private var requestedFrameIndex: Int!
    private var requestedFrameIndexes: IndexSet!
    
    private var cachedFrameIndexes: IndexSet!
    private var cachedFramesForIndexes: Dictionary<Int, UIImage>!
    
    private var allFramesIndexSet: IndexSet!
    
    private var imageSource: CGImageSource!
    private var data: Data!
    private var weakProxy: NGWeakProxy!
    
    // MARK: - Life Cycle
    
    init?(gifData: Data, optimalFrameCacheSize: Int = 0, shouldPredraw: Bool = true) {
        
        guard !gifData.isEmpty else {
            print("No animated GIF data supplied")
            return nil
        }
        
        guard let imgSource = CGImageSourceCreateWithData(gifData as CFData, [kCGImageSourceShouldCache as String : false as NSNumber] as CFDictionary),
            let imgType = CGImageSourceGetType(imgSource), UTTypeConformsTo(imgType, kUTTypeGIF) else {
                print("Failed to `CGImageSourceCreateWithData` for animated GIF data")
                return nil
        }
        
        let imageCount = CGImageSourceGetCount(imgSource)
        
        if imageCount == 0 {
            return nil
        } else if imageCount == 1 {
            
        }
        
        data = gifData
        frameCount = imageCount
        imageSource = imgSource
        isPredrawingEnabled = shouldPredraw
        
        var skippedFrameCount = 0
        
        cachedFramesForIndexes = [:]
        cachedFrameIndexes = IndexSet()
        requestedFrameIndexes = IndexSet()
        
        if let gifProperties = CGImageSourceCopyProperties(imageSource, nil) as? Dictionary<String, Any>,
            let fileSize = gifProperties[kCGImagePropertyFileSize as String] as? Int {
            
            self.fileSize = fileSize
        }
        
        var delayTimesForIndexesMutable: [Int: TimeInterval] = Dictionary(minimumCapacity: imageCount)
        
        for i in 0..<frameCount {
            
            if let frameCGImage = CGImageSourceCreateImageAtIndex(imageSource, i, nil) {
                let frameImage = UIImage(cgImage: frameCGImage)
                
                // set poster image
                if posterImage == nil {
                    
                    posterImage = frameImage
                    size = posterImage.size
                    posterImageFrameIndex = i
                    cachedFramesForIndexes[posterImageFrameIndex] = posterImage
                    cachedFrameIndexes.insert(posterImageFrameIndex)
                }
                
                // get delay time
                let frameProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil) as! Dictionary<String, Any>
                let framePropertiesGIF = frameProperties[kCGImagePropertyGIFDictionary as String] as! Dictionary<String, Any>
                
                var tmpDelayTime = framePropertiesGIF[kCGImagePropertyGIFUnclampedDelayTime as String] as? TimeInterval
                tmpDelayTime = tmpDelayTime ?? (framePropertiesGIF[kCGImagePropertyGIFDelayTime as String] as? TimeInterval)
                
                var delayTime = tmpDelayTime ?? (i == 0 ? kGIFDelayTimeIntervalDefault : delayTimesForIndexesMutable[i - 1]!)
                
                let baseValue = kGIFDelayTimeIntervalMinium - Double.ulpOfOne
                
                if delayTime < baseValue {
                    delayTime = kGIFDelayTimeIntervalDefault
                }
                
                delayTimesForIndexesMutable[i] = delayTime
                totalDelayTime += delayTime
                
            } else {
                
                skippedFrameCount += 1
            }
        }
        
        delayTimesForIndexes = delayTimesForIndexesMutable
        
        // 根据 gif 占用的内存大小确定缓存的帧数
        if optimalFrameCacheSize == 0 {
            let animatedImageDataSize = posterImage.cgImage!.bytesPerRow * Int(size.height) * (frameCount - skippedFrameCount) / MEGABYTE
            
            if animatedImageDataSize <= GIFDataSizeType.small.rawValue {
                frameCacheSizeOptimal = frameCount
            } else if animatedImageDataSize <= GIFDataSizeType.normal.rawValue {
                frameCacheSizeOptimal = CacheSizeOption.default.rawValue
            } else {
                frameCacheSizeOptimal = CacheSizeOption.lowMemory.rawValue
            }
            
        } else {
            frameCacheSizeOptimal = optimalFrameCacheSize
        }
        
        frameCacheSizeOptimal = min(frameCacheSizeOptimal, frameCount)
        allFramesIndexSet = IndexSet(integersIn: 0..<frameCount)
        
        super.init()

        // 监测内存警告
        weakProxy = NGWeakProxy(target: self)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didReceiveMemoryWarning(notification:)),
                                               name: Notification.Name.UIApplicationDidReceiveMemoryWarning,
                                               object: nil)
    }
    
    deinit {
        if weakProxy != nil {
            NSObject.cancelPreviousPerformRequests(withTarget: weakProxy)
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Get & Set Frame
    
    public func imageLazilyCachedAt(index: Int) -> UIImage? {
        guard index < frameCount else { return nil }
        requestedFrameIndex = index

        if cachedFramesForIndexes.count < frameCount {
            
            var frameIndexesToAddToCache = frameIndexesToCache
            
            frameIndexesToAddToCache.subtract(cachedFrameIndexes)
            frameIndexesToAddToCache.subtract(requestedFrameIndexes)
            frameIndexesToAddToCache.remove(posterImageFrameIndex)
            
            if !frameIndexesToAddToCache.isEmpty {
                addFrameIndexesToCache(frameIndexesToAddToCache)
            }
        }
        
        purgeFrameCacheIfNeeded()
        
        return cachedFramesForIndexes[index]
    }
    
    private func addFrameIndexesToCache(_ frameIndexesToAddToCache: IndexSet) {
        
        let firstRange = NSMakeRange(requestedFrameIndex, frameCount - requestedFrameIndex)
        let secondRange = NSMakeRange(0, requestedFrameIndex)
        
        requestedFrameIndexes.formUnion(frameIndexesToAddToCache)
        
        if serialQueue == nil {
            serialQueue = DispatchQueue(label: "com.notGIF.framecachingqueue")
        }
        
        serialQueue.async { [weak self] in
            
            let theFrameIndexes = NSIndexSet(indexSet: frameIndexesToAddToCache)
            
            let frameRangeBlock: (NSRange, UnsafeMutablePointer<ObjCBool>) -> Void = { (range, stop) in
                
                for i in range.location ..< NSMaxRange(range) {
                    if let sSelf = self,
                        let image = sSelf.imageAt(index: i) {
                        
                        DispatchQueue.main.async {
                            sSelf.cachedFramesForIndexes[i] = image
                            sSelf.cachedFrameIndexes.insert(i)
                            sSelf.requestedFrameIndexes.remove(i)
                        }
                    }
                }
            }
            
            theFrameIndexes.enumerateRanges(in: firstRange, options: NSEnumerationOptions(rawValue: 0), using: frameRangeBlock)
            theFrameIndexes.enumerateRanges(in: secondRange, options: NSEnumerationOptions(rawValue: 0), using: frameRangeBlock)
        }
    }
    
    private func imageAt(index: Int) -> UIImage? {
        guard let cgimage = CGImageSourceCreateImageAtIndex(imageSource, index, nil) else { return nil }
        let image = UIImage(cgImage: cgimage)
        if isPredrawingEnabled {
            return predrawnImageFrom(imageToPredraw: image)
        } else {
            return image
        }
    }
    
    // MARK: - Frame Caching
    
    private var frameIndexesToCache: IndexSet {
        
        var indexesToCache: IndexSet
        
        if frameCacheSizeCurrent == frameCount {
            indexesToCache = allFramesIndexSet
            
        } else {
            indexesToCache = IndexSet()
            
            let firstLength = min(frameCacheSizeCurrent, frameCount - requestedFrameIndex)
            indexesToCache.insert(integersIn: requestedFrameIndex..<requestedFrameIndex+firstLength)
            
            let secondLegth = frameCacheSizeCurrent - firstLength
            
            if secondLegth > 0 {
                let secondRange = 0..<secondLegth
                indexesToCache.insert(integersIn: secondRange)
            }
            
            indexesToCache.insert(posterImageFrameIndex)
        }
        
        return indexesToCache
    }
    
    private var frameCacheSizeCurrent: Int {
        var frameCacheSizeCurrent: Int = frameCacheSizeOptimal
        
        if frameCacheSizeMax > CacheSizeOption.noLimit.rawValue {
            frameCacheSizeCurrent = min(frameCacheSizeCurrent, frameCacheSizeMax)
        }
        
        if frameCacheSizeMaxInternal > CacheSizeOption.noLimit.rawValue {
            frameCacheSizeCurrent = min(frameCacheSizeCurrent, frameCacheSizeMaxInternal)
        }
        
        return frameCacheSizeCurrent
    }
    
    private func purgeFrameCacheIfNeeded() {
        if cachedFrameIndexes.count > frameCacheSizeCurrent {
            
            let indexesToPurge = NSMutableIndexSet(indexSet: cachedFrameIndexes)
            indexesToPurge.remove(frameIndexesToCache)
            
            indexesToPurge.enumerateRanges({ (range, stop) in
                for i in range.location ..< NSMaxRange(range) {
                    cachedFrameIndexes.remove(i)
                    cachedFramesForIndexes.removeValue(forKey: i)
                }
            })
        }
    }
    
    // MARK: - Image Decoding
    
    private func predrawnImageFrom(imageToPredraw: UIImage) -> UIImage {
        
        let colorSpaceDeviceRGB = CGColorSpaceCreateDeviceRGB()
        
        let width = Int(imageToPredraw.size.width)
        let height = Int(imageToPredraw.size.height)
        let bitsPerComponent = CHAR_BIT
        
        /* https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_context/dq_context.html#//apple_ref/doc/uid/TP30001066-CH203-BCIBHHBB
         let numberOfComponents = colorSpaceDeviceRGB.numberOfComponents + 1 // 4: RGB + A
         let bitsPerPixel = bitsPerComponent * Int32(numberOfComponents)
         let bytesPerPixel = bitsPerPixel / BYTE_SIZE
         let bytesPerRow = Int(bytesPerPixel) * width
         */
        let bytesPerRow = 0 // 系统自动计算 & cache line alignment 优化 https://stackoverflow.com/a/23791660/4696807
        
        // https://stackoverflow.com/a/24071985/4696807
        var alphaInfo = imageToPredraw.cgImage!.alphaInfo
        var bitmapInfo = CGBitmapInfo.byteOrder32Little
        
        if alphaInfo == .none || alphaInfo == .alphaOnly {
            alphaInfo = .noneSkipFirst
        } else if alphaInfo == .first {
            alphaInfo = .premultipliedFirst
        } else if alphaInfo == .last {
            alphaInfo = .premultipliedLast
        }
        
        bitmapInfo = CGBitmapInfo(rawValue: bitmapInfo.rawValue | alphaInfo.rawValue)
        
        let data: UnsafeMutableRawPointer? = nil    // 系统自动分配所需内存
        
        if let context = CGContext(data: data, width: width, height: height, bitsPerComponent: Int(bitsPerComponent), bytesPerRow: bytesPerRow, space: colorSpaceDeviceRGB, bitmapInfo: bitmapInfo.rawValue) {
            
            context.draw(imageToPredraw.cgImage!, in: CGRect(x: 0, y: 0, width: imageToPredraw.size.width, height: imageToPredraw.size.height))
            
            if let predrawnImage = context.makeImage() {
                return UIImage(cgImage: predrawnImage, scale: imageToPredraw.scale, orientation: imageToPredraw.imageOrientation)
                
            } else {
                return imageToPredraw
            }
            
        } else {
            return imageToPredraw
        }
        
    }
    
    // MARK: - Memory Warning Handler
    private var memoryWarningCount: Int = 0
    
    private var frameCacheSizeMaxInternal: Int = 0 {
        willSet {
            if frameCacheSizeMaxInternal != newValue && newValue < frameCacheSizeCurrent {
                purgeFrameCacheIfNeeded()
            }
        }
    }
    
    func didReceiveMemoryWarning(notification: Notification) {
        memoryWarningCount += 1
        
        NSObject.cancelPreviousPerformRequests(withTarget: weakProxy, selector: #selector(growFrameCacheSizeAfterMemoyWarning(frameCacheSize:)), object: [CacheSizeOption.afterMemoryWarning.rawValue])
        NSObject.cancelPreviousPerformRequests(withTarget: weakProxy, selector: #selector(resetFrameCacheSizeMaxInternal), object: nil)
        
        frameCacheSizeMaxInternal = CacheSizeOption.lowMemory.rawValue
        
        let kGrowAttemptsMax = 2
        let kGrowDelay: TimeInterval = 2.0
        
        // 记录内存警告的次数，若没有超过临界值，则在释放完内存后尝试提高缓存帧数
        if memoryWarningCount - 1 <= kGrowAttemptsMax {
            self.perform(#selector(growFrameCacheSizeAfterMemoyWarning(frameCacheSize:)), with: [CacheSizeOption.afterMemoryWarning.rawValue], afterDelay: kGrowDelay)
        }
    }
    
    func growFrameCacheSizeAfterMemoyWarning(frameCacheSize: Int) {
        frameCacheSizeMaxInternal = frameCacheSize
        let kResetDelay = 3.0
        weakProxy.perform(#selector(resetFrameCacheSizeMaxInternal), with: nil, afterDelay: kResetDelay)
    }
    
    func resetFrameCacheSizeMaxInternal() {
        frameCacheSizeMaxInternal = CacheSizeOption.noLimit.rawValue
    }
}
