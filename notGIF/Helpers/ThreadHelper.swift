//
//  ThreadHelper.swift
//  notGIF
//
//  Created by Atuooo on 30/05/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import Foundation

class DispatchQueuePool {
    fileprivate var queues: [DispatchQueue]
    fileprivate var currentIndex: Int = 0
    
    init(name: String, qos: DispatchQoS, queueCount: Int) {
        queues = []
        
        for i in 0 ..< queueCount {
            let queue = DispatchQueue(label: name + "queue\(i)", qos: qos)
            queues.append(queue)
        }
    }
    
    public var queue: DispatchQueue {
        currentIndex = (currentIndex + 1) % queues.count
        return queues[currentIndex]
    }
    
    deinit {
        queues.removeAll()
    }
}

extension DispatchQueue {
    func safeAsync(_ block: @escaping ()->()) {
        if self === DispatchQueue.main && Thread.isMainThread {
            block()
        } else {
            async { block() }
        }
    }
}
