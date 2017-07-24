//
//  FrameDetailLayout.swift
//  notGIF
//
//  Created by Atuooo on 23/07/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

public class FrameDetailLayout: UICollectionViewFlowLayout {
    
    fileprivate lazy var currentPage: CGFloat = {
        guard let offsetX = self.collectionView?.contentOffset.x else {
            return 0
        }
        return round(offsetX / self.pageW)
    }()

    fileprivate var pageW: CGFloat {
        return minimumLineSpacing + itemSize.width
    }
    
    fileprivate var maxPage: CGFloat {
        guard let contentW = collectionView?.contentSize.width else { return 0 }
        return (contentW+minimumLineSpacing) / pageW
    }
    
    init(size: CGSize, spacing: CGFloat) {
        super.init()
        
        scrollDirection = .horizontal
        itemSize = size
        minimumLineSpacing = spacing
        minimumInteritemSpacing = 0
    }
        
    public override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        
        var page = round(proposedContentOffset.x / pageW)
        if velocity.x > 0.2 {
            page += 1
        } else if velocity.x < -0.2 {
            page -= 1
        }
        
        if page - currentPage >= 1.0 {
            page = currentPage + 1
        }
        if page - currentPage <= -1.0 {
            page = currentPage - 1
        }
        
        currentPage = max(0, min(page, maxPage))
        return CGPoint(x: page * pageW, y: 0)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
