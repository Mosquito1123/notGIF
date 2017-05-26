//
//  RealmConfig.swift
//  notGIF
//
//  Created by Atuooo on 26/05/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import Foundation
import RealmSwift

public func realmConfig(readOnly: Bool = false) -> Realm.Configuration {
    
    let directory: URL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Config.appGroupID)!
    let realmFileURL = directory.appendingPathComponent("notGIF.realm")
    
    var config = Realm.Configuration()
    config.fileURL = realmFileURL
    config.readOnly = readOnly
    config.schemaVersion = 1
    config.migrationBlock = { migration, oldSchemaVersion in
        
    }
    
    return config
}
