//
//  FrameListCell.swift
//  notGIF
//
//  Created by Atuooo on 21/07/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

class FrameListCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var indexLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imageView.image = nil
        indexLabel.text = nil
    }
}
