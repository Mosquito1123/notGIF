//
//  NotGIFImageLayer.swift
//  notGIF
//
//  Created by Atuooo on 29/05/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

class NotGIFImageLayer: CALayer {
    public var currentFrame: CGImage!
    
    public var currentFrameIndex = 0
    
    private var accumulator: TimeInterval = 0.0
    private var displayLink: CADisplayLink?
    
    private var shouldAnimate: Bool = false
    private var needsDisplayWhenImageBecomesAvailable: Bool = true
    
    private var runLoopMode: RunLoopMode {
        return ProcessInfo.processInfo.activeProcessorCount > 1 ? .commonModes : .defaultRunLoopMode
    }

}
