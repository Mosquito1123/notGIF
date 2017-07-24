//
//  FrameDetailCell.swift
//  notGIF
//
//  Created by Atuooo on 21/07/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

protocol FrameDetailCellDelegate: class {
    func didBeginZoom()
    func didLongPress()
    func didTap()
}

class FrameDetailCell: UICollectionViewCell {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    
    public weak var delegate: FrameDetailCellDelegate?
    fileprivate var maxZoomScale: CGFloat = 2
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.isUserInteractionEnabled = true
        imageView.clipsToBounds = true

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(FrameDetailCell.onDoubleTap(ges:)))
        doubleTap.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTap)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(FrameDetailCell.onLongPress(ges:)))
        imageView.addGestureRecognizer(longPress)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(FrameDetailCell.onTap(ges:)))
        contentView.addGestureRecognizer(tap)
        
        tap.require(toFail: doubleTap)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        scrollView.setZoomScale(1.0, animated: false)
        imageView.image = nil
    }
    
    public func reset() {
        scrollView.setZoomScale(1.0, animated: false)
    }
    
    public func configureWith(_ image: UIImage) {
        
        var imageViewW = bounds.width
        var imageViewH = imageViewW / image.size.width  * image.size.height
        
        maxZoomScale = max(2.0, bounds.height / imageViewH)
        
        if imageViewH > bounds.height {
            imageViewH = bounds.height
            imageViewW = imageViewH / image.size.height  * image.size.width
            maxZoomScale = max(2.0, bounds.width / imageViewW)
        }
        
        imageView.frame.size = CGSize(width: imageViewW, height: imageViewH)
        imageView.center = CGPoint(x: bounds.width/2, y: bounds.height/2)
        
        imageView.image = image
        scrollView.maximumZoomScale = maxZoomScale
    }
    
    // MARK: - Gesture Handler
    func onDoubleTap(ges: UITapGestureRecognizer) {
        if scrollView.zoomScale == 1.0 {
            let pointInView = ges.location(in: imageView)
            let w = imageView.bounds.width / maxZoomScale
            let h = imageView.bounds.height / maxZoomScale
            let x = pointInView.x - w/2
            let y = pointInView.y - h/2
            scrollView.zoom(to: CGRect(x: x, y: y, width: w, height: h), animated: true)
        } else {
            scrollView.setZoomScale(1.0, animated: true)
        }
    }
    
    func onLongPress(ges: UILongPressGestureRecognizer) {
        delegate?.didLongPress()
    }
    
    func onTap(ges: UITapGestureRecognizer) {
        delegate?.didTap()
    }
}

// MARK: - UIScrollView Delegate
extension FrameDetailCell: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let deltaWidth = bounds.width - scrollView.contentSize.width
        let offsetX = deltaWidth > 0 ? deltaWidth * 0.5 : 0
        let deltaHeight = bounds.height - scrollView.contentSize.height
        let offsetY = deltaHeight > 0 ? deltaHeight * 0.5 : 0
        imageView.center =  CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX,
                                    y: scrollView.contentSize.height * 0.5 + offsetY)
        
        delegate?.didBeginZoom()
    }
}
