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
    dynamic var modifyDate: Date!
    
    let gifs = List<NotGIF>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(id: String = UUID().uuidString, name: String, date: Date = Date()) {
        self.init()
        
        self.id = id
        self.name = name
        createDate = date
        modifyDate = date
    }
}

extension Tag {
    
    var localNameStr: String {
        return id == Config.defaultTagID ? String.trans_tagAll : name
    }
    
    public func update(with name: String) -> Tag {
        modifyDate = Date()
        self.name = name
        return self
    }
    
    func remove(notGIF: NotGIF) {
        
    }
}
