//
//  GIFListCollectionViewCell.swift
//  notGIF
//
//  Created by Atuooo on 09/10/2016.
//  Copyright © 2016 xyz. All rights reserved.
//

import UIKit

class MGIFListViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: NotGIFImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.animateImage = nil
    }
}
