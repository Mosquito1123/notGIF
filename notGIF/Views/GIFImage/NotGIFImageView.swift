//
//  NotGIFImageView.swift
//  notGIF
//
//  Created by ooatuoo on 2017/5/13.
//  Copyright © 2017年 xyz. All rights reserved.
//
//  The NotGIFImage and NotGIFImageView is a modified Swift version of
//  some classes from Flipboard's FLAnimatedImage project (https://github.com/Flipboard/FLAnimatedImage)

import UIKit

class NotGIFImageView: UIImageView {
    
    public var shouldUpdateImmediately: Bool = true
    public var currentFrame: UIImage!
    
    public var currentFrameIndex: Int {
        set {
            guard animateImage != nil else { return }
            _currentFrameIndex = newValue >= animateImage.frameCount ? 0 : newValue
        }
        get {
            return _currentFrameIndex
        }
    }
    
    private var _currentFrameIndex = 0
    
    public var animateImage: NotGIFImage! {
        didSet {
            guard animateImage != oldValue else { return }
            resetSpeed()
            
            if animateImage != nil {
                super.image = nil
                super.isHighlighted = false
                super.invalidateIntrinsicContentSize()
                
                currentFrame = animateImage.posterImage
                currentFrameIndex = animateImage.currentIndexForContinue
                
                timeSinceLastFrameChange = 0.0
                
                updateShouldAnimate()
                
                if shouldAnimate {
                    startAnimating()
                }
                
                layer.setNeedsDisplay()
                
            } else {
                stopAnimating()
                super.image = nil
                layer.contents = nil
            }
        }
    }
    
    private var manualSpeed: TimeInterval?
    
    private var timeSinceLastFrameChange: TimeInterval = 0.0
    private var displayLink: CADisplayLink?
    
    private var shouldAnimate: Bool = false
    private var needsDisplayWhenImageBecomesAvailable: Bool = true
    
    private var runLoopMode: RunLoopMode {
        return ProcessInfo.processInfo.activeProcessorCount > 1 ? .commonModes : .defaultRunLoopMode
    }
    
    // MARK: - Life Cycle
    deinit {
        displayLink?.invalidate()
        displayLink = nil
        printLog("deinited")
    }
    
    // MARK: - Change Speed
    public func updateSpeed(_ speed: TimeInterval) {
        guard manualSpeed != speed else { return }
        if #available(iOS 10.0, *) {
            displayLink?.preferredFramesPerSecond = speed < 0.02 ? 200 : 60
        } else {
            displayLink?.frameInterval = speed < 0.02 ? 4 : 1
        }
        
        manualSpeed = speed
        layer.setNeedsDisplay()
    }
    
    public func resetSpeed() {
        manualSpeed = nil
        if #available(iOS 10.0, *) {
            displayLink?.preferredFramesPerSecond = 60
        } else {
            displayLink?.frameInterval = 1
        }
    }
    
    // MARK: - Animating Image
    
    func displayDidRefresh(dpLink: CADisplayLink) {
        
        guard animateImage != nil, shouldAnimate else { return }
        defer { animateImage.currentIndexForContinue = currentFrameIndex }
        
        let delay = manualSpeed ?? animateImage.delayTimesForIndexes[currentFrameIndex]
        
        if let frameDuration = delay {
            
            if let frame = animateImage.imageLazilyCachedAt(index: currentFrameIndex) {
                
                currentFrame = frame
                
                if needsDisplayWhenImageBecomesAvailable {
                    layer.setNeedsDisplay()
                    needsDisplayWhenImageBecomesAvailable = false
                }
                
                timeSinceLastFrameChange += dpLink.duration
                while timeSinceLastFrameChange >= frameDuration {
                    timeSinceLastFrameChange -= frameDuration
                    currentFrameIndex += 1
    
                    needsDisplayWhenImageBecomesAvailable = true
                }
                
            } else {
                // 等待下一帧图片准备好
            }
            
        } else {
            // 如获取不到间隔时间，直接跳过
            currentFrameIndex += 1
        }
    }
    
    override func display(_ layer: CALayer) {
        layer.contents = currentFrame.cgImage
    }
    
    override func startAnimating() {
        guard animateImage != nil else { super.startAnimating(); return }
        
        currentFrameIndex = animateImage.currentIndexForContinue
        
        if shouldUpdateImmediately {
            if let frame = animateImage.imageLazilyCachedAt(index: currentFrameIndex) {
                currentFrame = frame
                layer.setNeedsDisplay()
            }
        }

        if displayLink == nil {
            displayLink = CADisplayLink(target: NGWeakProxy(target: self), selector: #selector(displayDidRefresh(dpLink:)))
            displayLink?.add(to: RunLoop.main, forMode: runLoopMode)
        }
        
        displayLink?.isPaused = false
    }
    
    override func stopAnimating() {
        
        guard animateImage != nil, let dpLink = displayLink else {
            displayLink?.isPaused = true
            super.stopAnimating()
            return
        }
        
        if dpLink.isPaused {    // 更新到最新的帧
            currentFrameIndex = animateImage.currentIndexForContinue
            
            if let frame = animateImage.imageLazilyCachedAt(index: currentFrameIndex) {
                currentFrame = frame
                layer.setNeedsDisplay()
            }
            
        } else {
            dpLink.isPaused = true
        }
    }
    
    override var isAnimating: Bool {
        if animateImage != nil {
            return displayLink?.isPaused ?? false
        } else {
            return super.isAnimating
        }
    }
    
    override var isHighlighted: Bool {
        set {
            // 防止嵌入到 UICollectionViewCell 引起的动图闪烁
            if animateImage == nil {
                super.isHighlighted = newValue
            }
        }
        get {
            return super.isHighlighted
        }
    }
    
    override var intrinsicContentSize: CGSize {
        if animateImage != nil {
            return animateImage.size
        } else {
            return super.intrinsicContentSize
        }
    }
    
    private func updateShouldAnimate() {
        let isVisible = superview != nil && !isHidden && alpha > 0
        shouldAnimate = animateImage != nil && isVisible
    }
    
    // MARK: - Help Method
    // 获取每帧间隔时间的最大公约数
    private var frameDelayGreatestCommonDivisor: TimeInterval {
        let kGreatestCommonDivisorPrecision = 2.0 / kGIFDelayTimeIntervalMinium
        let delays = animateImage.delayTimesForIndexes.map {$0.value}
        var scaleGCD = lrint(delays.first! * kGreatestCommonDivisorPrecision)
        
        for value in delays {
            scaleGCD = gcd(lrint(value * kGreatestCommonDivisorPrecision), scaleGCD)
        }
        
        return TimeInterval(scaleGCD) / kGreatestCommonDivisorPrecision
    }
    
    private func gcd(_ a: Int, _ b: Int) -> Int {
        if a < b {
            return gcd(b, a)
        } else if a == b {
            return b
        }
        
        var aV = a, bV = b
        
        while true {
            let remainder = aV % bV
            
            if remainder == 0 {
                return bV
            }
            
            aV = bV
            bV = remainder
        }
    }
}
