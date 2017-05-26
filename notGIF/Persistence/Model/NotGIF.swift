//
//  NotGIF.swift
//  notGIF
//
//  Created by Atuooo on 26/05/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import Foundation
import RealmSwift

class NotGIF: Object {
    
    dynamic var id: String = ""     // localIdentifier
    dynamic var width: Double = 0
    dynamic var height: Double = 0
    
    dynamic var creationDate: Date!
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
