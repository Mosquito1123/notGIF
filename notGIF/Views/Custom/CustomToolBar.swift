//
//  CustomToolBar.swift
//  notGIF
//
//  Created by Atuooo on 17/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

class CustomToolBar: UIToolbar {
    
    var doneButtonHandler: CommonHandler?
    var cancelButtonHandler: CommonHandler?

    fileprivate lazy var doneButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 40))
        button.setTitle(String.trans_titleDone, for: .normal)
        button.setTitleColor(UIColor.darkText, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.addTarget(self, action: #selector(CustomToolBar.doneButtonClicked), for: .touchUpInside)
        return button
    }()
    
    fileprivate lazy var cancelButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 40))
        button.setTitle(String.trans_titleCancel, for: .normal)
        button.setTitleColor(UIColor.darkText, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.addTarget(self, action: #selector(CustomToolBar.cancelButtonClicked), for: .touchUpInside)
        return button
    }()
    
    func doneButtonClicked() {
        doneButtonHandler?()
    }
    
    func cancelButtonClicked() {
        cancelButtonHandler?()
    }
    
    init(doneHandler: @escaping CommonHandler, cancelHandler: @escaping CommonHandler) {
        super.init(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: 40))

        doneButtonHandler = doneHandler
        cancelButtonHandler = cancelHandler
        
        backgroundColor = UIColor.lightGray
        let doneItem = UIBarButtonItem(customView: doneButton)
        let cancelItem = UIBarButtonItem(customView: cancelButton)
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        items = [space, cancelItem, space, space, doneItem, space]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
