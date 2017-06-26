//
//  Realm+NG.swift
//  notGIF
//
//  Created by Atuooo on 18/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import Foundation
import RealmSwift

public extension List {
    func add(object: Element, update: Bool) {
        if update {
            if !contains(object) {
                append(object)
            }
        } else {
            append(object)
        }
    }
    
    func add<S: Sequence>(objectsIn objects: S, update: Bool) where S.Iterator.Element == T {
        if update {
            objects.forEach{ add(object: $0, update: true) }
        } else {
            append(objectsIn: objects)
        }
    }
    
    func remove(_ object: Element) {
        if let index = index(of: object) {
            remove(objectAtIndex: index)
        }
    }
    
    func remove<S: Sequence>(objectsIn objects: S) where S.Iterator.Element == T {
        objects.forEach {
            remove($0)
        }
    }
}
