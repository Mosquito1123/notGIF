//
//  RealmConfig.swift
//  notGIF
//
//  Created by Atuooo on 05/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import Foundation
import RealmSwift

public func realmConfig(readOnly: Bool = false) -> Realm.Configuration {
    
    let directory: URL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Config.appGroupID)!
    let realmFileURL = directory.appendingPathComponent("notGIF.realm")
    print(realmFileURL)
    
    var config = Realm.Configuration()
    config.fileURL = realmFileURL
    config.readOnly = readOnly
    config.schemaVersion = 2
    config.migrationBlock = { migration, oldSchemaVersion in
        
    }
    
    return config
}

public func prepareRealm() {
    guard let realm = try? Realm() else { return }
    
    if let _ = realm.object(ofType: Tag.self, forPrimaryKey: Config.defaultTagID) {
        
    } else {
        
        // 创建于 100 年后
        let date = Date(timeIntervalSinceNow: 3153600000) 
        let defaultTag = Tag(id: Config.defaultTagID, name: "所有", date: date)

        try? realm.write {
            realm.add(defaultTag, update: true)
        }
    }
}
