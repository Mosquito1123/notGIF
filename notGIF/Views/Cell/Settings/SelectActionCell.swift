//
//  SelectActionCell.swift
//  notGIF
//
//  Created by Atuooo on 25/07/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

fileprivate let itemSize: CGFloat = 36

class SelectActionCell: UITableViewCell {
    static let height: CGFloat = 200
    
    fileprivate var emptyIndexes: IndexSet = []
    fileprivate var currentActions: [GIFActionType] = [] {
        didSet {
            NGUserDefaults.customActions = currentActions   
        }
    }

    fileprivate lazy var allActions: [GIFActionType] = {
        return GIFActionType.allActionValues.flatMap{ GIFActionType.initWith($0) }
    }()
    
    fileprivate var currentActionFrames: [CGRect] = []
    fileprivate var allActionFrames: [CGRect] = []
    
    fileprivate lazy var hintLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.textTint
        label.text = String.trans_titleCustomAction
        label.textAlignment = .center
        label.font = UIFont.menlo(ofSize: 16)
        return label
    }()
    
    fileprivate lazy var addHintLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.textTint.withAlphaComponent(0.7)
        label.text = String.trans_titleTapToAddAction
        label.textAlignment = .center
        label.font = UIFont.menlo(ofSize: 15)
        return label
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = UIColor.commonBg
        separatorInset = UIEdgeInsets(top: 0, left: kScreenWidth, bottom: 0, right: 0)
        selectionStyle = .none
        
        currentActions = NGUserDefaults.customActions
        
        if !OpenShare.canOpen(.wechat) {
            currentActions.remove(.shareTo(.wechat))
        }
        
        emptyIndexes.insert(integersIn: currentActions.count..<Config.maxCustomActionCount)
        printLog(emptyIndexes)
        makeUI()
    }
    
    // MARK: - Button Action
    
    func actionButtonClicked(button: UIButton) {
        func animateMoveTo(finalRect: CGRect) {
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.6, options: [], animations: { 
                button.frame = finalRect
            }, completion: nil)
        }
        
        guard let actionType = GIFActionType.initWith(button.tag) else { return }
        
        if button.center.y < bounds.height/2 {  // remove from current
            let index = allActions.index(of: actionType)!
            currentActions.remove(actionType)
            if let rIndex = currentActionFrames.index(of: button.frame) {
                emptyIndexes.insert(rIndex)
            }
            
            animateMoveTo(finalRect: allActionFrames[index])
            
        } else {    // add to current
            guard currentActions.count < Config.maxCustomActionCount else { return }
            let index = emptyIndexes.min() ?? 0
            animateMoveTo(finalRect: currentActionFrames[index])
            currentActions.insert(actionType, at: index)
            emptyIndexes.remove(index)
        }
    }
    
    // MARK: - Helper
    
    fileprivate func makeUI() {
        // current bgViews
        let cSpace: CGFloat = 12
        let currentCount = Config.maxCustomActionCount
        let cOy: CGFloat = SelectActionCell.height/2 - itemSize - 12
        var cOx = (kScreenWidth - CGFloat(currentCount)*itemSize - CGFloat(currentCount-1)*cSpace)/2
        
        for _ in 0..<currentCount {
            let rect = CGRect(x: cOx, y: cOy, width: itemSize, height: itemSize)
            let bgView = UIView(frame: rect)
            bgView.backgroundColor = UIColor.hex(0x1b1b1b)
            bgView.layer.cornerRadius = itemSize / 2
            bgView.layer.masksToBounds = true
            contentView.addSubview(bgView)
            
            currentActionFrames.append(rect)
            cOx += cSpace+itemSize
        }
        
        // all bgViews
        let allCount = allActions.count
        let aOy = SelectActionCell.height / 2 + 46
        var aOx: CGFloat = 15
        let aSpace = (kScreenWidth-aOx*2-CGFloat(allCount)*itemSize)/CGFloat(allCount-1)
        
        for action in allActions {
            let bgView = UIImageView(image: action.icon)
            bgView.frame = CGRect(x: aOx, y: aOy, width: itemSize, height: itemSize)
            bgView.contentMode = .center
            bgView.tintColor = UIColor.textTint.withAlphaComponent(0.7)
            bgView.backgroundColor = UIColor.hex(0x1b1b1b)
            bgView.layer.cornerRadius = itemSize / 2
            bgView.layer.masksToBounds = true
            contentView.addSubview(bgView)
            
            allActionFrames.append(bgView.frame)
            aOx += itemSize+aSpace
        }
        
        // action buttons
        var buttonActions = allActions
        if !OpenShare.canOpen(.wechat) {
            buttonActions.remove(.shareTo(.wechat))
        }
        
        for item in buttonActions {
            let button = UIButton()
            button.tag = item.hashValue
            button.backgroundColor = UIColor.black
            button.tintColor = UIColor.textTint
            button.setImage(item.icon, for: .normal)
            button.layer.cornerRadius = itemSize / 2
            button.layer.masksToBounds = true
            button.layer.borderWidth = 1.2
            button.layer.borderColor = UIColor.textTint.cgColor
            button.addTarget(self, action: #selector(SelectActionCell.actionButtonClicked(button:)), for: .touchUpInside)
            
            if let currentIndex = currentActions.index(of: item) {
                button.frame = currentActionFrames[currentIndex]
            } else if let allIndex = allActions.index(of: item) {
                button.frame = allActionFrames[allIndex]
            }
            
            contentView.addSubview(button)
        }
        
        // separator line
        let line = UIView()
        line.backgroundColor = UIColor.lightGray.withAlphaComponent(0.8)
        contentView.addSubview(line)
        
        line.snp.makeConstraints { make in
            make.right.equalTo(-18)
            make.left.equalTo(18)
            make.centerY.equalTo(contentView)
            make.height.equalTo(0.5)
        }
        
        // add hint label
        contentView.addSubview(addHintLabel)
        contentView.addSubview(hintLabel)
        
        hintLabel.snp.makeConstraints { make in
            make.right.left.equalTo(contentView)
            make.top.equalTo(12)
        }
        
        addHintLabel.snp.makeConstraints { make in
            make.right.left.equalTo(contentView)
            make.top.equalTo(contentView.snp.centerY).offset(12)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
