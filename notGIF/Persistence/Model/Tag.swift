//
//  Tag.swift
//  notGIF
//
//  Created by Atuooo on 26/05/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import RealmSwift

class Tag: Object {
    
    dynamic var id: String      = ""     // UUID
    dynamic var name: String    = ""
    
    dynamic var createDate: Date!
    
    let gifs = List<NotGIF>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
