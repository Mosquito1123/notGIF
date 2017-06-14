//
//  UICollectionView+NG.swift
//  notGIF
//
//  Created by ooatuoo on 2017/6/7.
//  Copyright © 2017年 xyz. All rights reserved.
//

import UIKit

extension UICollectionView {
    
    func registerClassOf<T: UICollectionReusableView>(_: T.Type) where T: Reusable {
        register(T.self, forCellWithReuseIdentifier: T.ng_reuseIdentifier)
    }
    
    func dequeueReusableCell<T: UICollectionReusableView>(for indexPath: IndexPath) -> T where T: Reusable {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.ng_reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.ng_reuseIdentifier)")
        }
        
        return cell
    }
    
    func registerFooterOf<T: UICollectionReusableView>(_: T.Type) where T: Reusable {
        register(T.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: T.ng_reuseIdentifier)
    }

    func dequeueReusableFooter<T: UICollectionReusableView>(for indexPath: IndexPath) -> T where T: Reusable {
        guard let footer = dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: T.ng_reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue footer with identifier: \(T.ng_reuseIdentifier)")
        }
        
        return footer
    }
}

