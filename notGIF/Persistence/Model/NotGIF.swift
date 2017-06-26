//
//  NotGIF.swift
//  notGIF
//
//  Created by Atuooo on 26/05/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import Foundation
import RealmSwift
import Photos

class NotGIF: Object {
    
    dynamic var id: String = ""     // localIdentifier
    dynamic var width: Int = 0
    dynamic var height: Int = 0
    
    dynamic var creationDate: Date!
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(asset: PHAsset) {
        self.init()
        
        id = asset.localIdentifier
        creationDate = asset.creationDate
        width = asset.pixelWidth
        height = asset.pixelHeight
    }
}

extension NotGIF {
    
    var ratio: CGFloat {
        return CGFloat(width) / CGFloat(height)
    }
}
