//
//  GIFListCollectionViewCell.swift
//  notGIF
//
//  Created by Atuooo on 09/10/2016.
//  Copyright © 2016 xyz. All rights reserved.
//

import UIKit

class GIFListCell: GIFBaseCell {
    
    @IBOutlet weak var timeLabel: UILabel!
    
    public var shareGIFHandler: ((ShareType) -> Void)?
    fileprivate var popShareView: LongPressPopShareView?
    
    fileprivate var isChoosed: Bool = false
    
    fileprivate lazy var chooseIndicator: UILabel = {
        let label = UILabel(iconCode: .checkO, color: UIColor.textTint, fontSize: 20)
        label.frame = CGRect(x: 6, y: 6, width: 26, height: 26)
        return label
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        timeLabel.text = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        timeLabel.text = nil
        
        let longPressGes = UILongPressGestureRecognizer(target: self, action: #selector(GIFListCell.longPressGesHandler(ges:)))
        addGestureRecognizer(longPressGes)
    }
    
    deinit {
        printLog("deinited")
    }
    
    public func update(isChoosed: Bool, animate: Bool) {
        
        guard self.isChoosed != isChoosed else { return }
        self.isChoosed = isChoosed
        
        func update() {
            if isChoosed {
                transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
                contentView.alpha = 0.3
                addSubview(self.chooseIndicator)
            } else {
                transform = .identity
                contentView.alpha = 1
                chooseIndicator.removeFromSuperview()
            }
        }
        
        if animate {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: [.allowAnimatedContent, .curveEaseInOut], animations: {
                update()
            }, completion: nil)
        } else {
            update()
        }
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
