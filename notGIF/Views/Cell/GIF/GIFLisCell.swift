//
//  GIFListCollectionViewCell.swift
//  notGIF
//
//  Created by Atuooo on 09/10/2016.
//  Copyright © 2016 xyz. All rights reserved.
//

import UIKit
import SnapKit

class GIFListCell: GIFBaseCell {
    
    @IBOutlet weak var timeLabel: UILabel!
    
    public var shareGIFHandler: ((ShareType) -> Void)?
    fileprivate var popShareView: LongPressPopShareView?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        timeLabel.text = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let longPressGes = UILongPressGestureRecognizer(target: self, action: #selector(GIFListCell.longPressGesHandler(ges:)))
        addGestureRecognizer(longPressGes)
    }
    
    func longPressGesHandler(ges: UILongPressGestureRecognizer) {
        let keyWindow = UIApplication.shared.keyWindow
        let location = ges.location(in: keyWindow)
        
        switch ges.state {
        case .began:
            if let cellFrame = superview?.convert(frame, to: keyWindow) {
                popShareView = LongPressPopShareView(popOrigin: location, cellRect: cellFrame)
                keyWindow?.addSubview(popShareView!)
            }
            
        case .changed:
            
            popShareView?.update(with: location)
            
        case .ended, .failed, .cancelled:
            
            if let type = popShareView?.end(with: location) {
                shareGIFHandler?(type)
            }
            
        default:
            break
        }
    }
}
