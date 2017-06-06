//
//  PHAsset+NG.swift
//  notGIF
//
//  Created by Atuooo on 04/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import Photos
import MobileCoreServices

extension PHAsset {
    var isGIF: Bool {
        guard let assetSource = PHAssetResource.assetResources(for: self).first else {
            return false
        }
        
        let uti = assetSource.uniformTypeIdentifier as CFString
        return UTTypeConformsTo(uti, kUTTypeGIF) || assetSource.originalFilename.hasSuffix("GIF")
    }
}

