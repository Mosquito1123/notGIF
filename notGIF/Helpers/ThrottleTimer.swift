//
//  ThrottleTimer.swift
//  notGIF
//
//  Created by ooatuoo on 2017/6/19.
//  Copyright © 2017年 xyz. All rights reserved.
//

import Foundation

class ThrottleTimer {
    static let shared = ThrottleTimer()
    
    fileprivate var timers: [String : DispatchSourceTimer] = [:]
    
    static func throttle(interval: TimeInterval, identifier: String, queue: DispatchQueue = .main, handler: @escaping () -> Void) {
        guard shared.timers[identifier] == nil else { return }
        
        handler()
        
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.scheduleOneshot(deadline: .now()+interval)
        timer.setEventHandler {
            timer.cancel()
            shared.timers.removeValue(forKey: identifier)
        }
        
        shared.timers[identifier] = timer
        timer.resume()
    }
}
