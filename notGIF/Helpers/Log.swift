//
//  Log.swift
//  notGIF
//
//  Created by Atuooo on 12/10/2016.
//  Copyright © 2016 xyz. All rights reserved.
//

import Foundation

func println(_ item: @autoclosure () -> Any) {
    #if DEBUG
        print("\(item())")
    #endif
}

func printLog<T>(_ message: T, file: String = #file, method: String = #function, line: Int = #line) {
    #if DEBUG
    print("\n\((file as NSString).lastPathComponent)[\(line)]: \n - \(method): \(message)\n")
    #endif
}
