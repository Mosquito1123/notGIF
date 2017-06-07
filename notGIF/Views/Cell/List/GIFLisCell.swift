//
//  GIFListCollectionViewCell.swift
//  notGIF
//
//  Created by Atuooo on 09/10/2016.
//  Copyright © 2016 xyz. All rights reserved.
//

import UIKit
import SnapKit

class GIFListCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: NotGIFImageView!
    @IBOutlet weak var timeLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.animateImage = nil
        timeLabel.text = nil
    }
}
