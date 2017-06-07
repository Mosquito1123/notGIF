//
//  CustomRowAction.swift
//  notGIF
//
//  Created by ooatuoo on 2017/6/7.
//  Copyright © 2017年 xyz. All rights reserved.
//

import UIKit

private let defaultTextPadding: CGFloat = 15

extension UITableViewRowAction {
    convenience init(size: CGSize, image: UIImage, bgColor: UIColor, handler: @escaping (UITableViewRowAction, IndexPath) -> Void) {
        
        self.init(style: .default, title: "", handler: handler)
        
        // calculate actual size & set title with spaces
        let defaultAttributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 18)]
        let oneSpaceWidth = NSString(string: " ").size(attributes: defaultAttributes).width
        let titleWidth = size.width - defaultTextPadding * 2
        let numOfSpace = Int(ceil(titleWidth / oneSpaceWidth))
        
        let placeHolder = String(repeating: " ", count: numOfSpace)
        let newWidth = (placeHolder as NSString).size(attributes: defaultAttributes).width + defaultTextPadding * 2
        let newSize = CGSize(width: newWidth, height: size.height)
        
        title = placeHolder
        
        // set background with pattern image
        UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.main.nativeScale)
        
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(bgColor.cgColor)
        context.fill(CGRect(origin: .zero, size: newSize))
        
        let originX = (newWidth - image.size.width) / 2
        let originY = (size.height - image.size.height) / 2
        image.draw(in: CGRect(x: originX, y: originY, width: image.size.width, height: image.size.height))
        let patternImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        
        backgroundColor = UIColor(patternImage: patternImage)
    }
}
