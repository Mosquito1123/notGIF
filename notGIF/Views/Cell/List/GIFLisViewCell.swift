//
//  GIFListCollectionViewCell.swift
//  notGIF
//
//  Created by Atuooo on 09/10/2016.
//  Copyright © 2016 xyz. All rights reserved.
//

import UIKit
import SnapKit

class GIFListViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: NotGIFImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.animateImage = nil
    }
}
