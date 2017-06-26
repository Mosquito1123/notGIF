//
//  GIFBaseCell.swift
//  notGIF
//
//  Created by ooatuoo on 2017/6/9.
//  Copyright © 2017年 xyz. All rights reserved.
//

import UIKit

class GIFBaseCell: UICollectionViewCell {
    
    public lazy var imageView: NotGIFImageView = NotGIFImageView()
    public var isInTransition: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        contentView.insertSubview(imageView, at: 0)
    }
        
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imageView.animateImage = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.frame = bounds
    }
    
    public func animating(enable: Bool) {
        if !isInTransition {
            enable ? imageView.startAnimating() : imageView.stopAnimating()
        }
    }
}
