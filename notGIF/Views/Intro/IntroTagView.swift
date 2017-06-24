//
//  IntroTagView.swift
//  notGIF
//
//  Created by Atuooo on 24/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

class IntroTagView: UIImageView, Intro, UITableViewDelegate, UITableViewDataSource {

    fileprivate let imageSacle: CGFloat = 0.8
    fileprivate var tagStrs: [String] = []
    fileprivate var tagCounts = [29, 8, 3, 5, 13]
    fileprivate var animated: Bool = false
    
    // 750 * 1334
    fileprivate lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.registerNibOf(TagListCell.self)
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.clear
        tableView.isUserInteractionEnabled = false
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    fileprivate lazy var logoView: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "icon_logo"))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    fileprivate lazy var addTagView: UIButton = {
        let button = UIButton()
        button.setTitle(String.trans_tag, for: .normal)
        button.setTitleColor(UIColor.textTint, for: .normal)
        button.setImage(#imageLiteral(resourceName: "icon_add_tag"), for: .normal)
        button.tintColor = UIColor.textTint
        button.titleLabel?.font = UIFont.menlo(ofSize: 17)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -16, bottom: 0, right: 0)
        button.isUserInteractionEnabled = false
        return button
    }()
    
    fileprivate var animateViews: [UIView] = []
    fileprivate var waitAnimate: Bool = true
    
    init() {
        // 750 * 1334
        let imageW = kScreenWidth * imageSacle
        let imageH = imageW / 750 * 1334
        
        let rect = CGRect(x: 0, y: 100, width: kScreenWidth, height: imageH)
        
        super.init(frame: rect)
        image = #imageLiteral(resourceName: "intro_tag_plain")
        contentMode = .scaleAspectFit
        
        if Config.isChinese {
            tagStrs = [String.trans_tagAll, "这很经典👏", "哦哦嗷🤖嗷嗯嗯", "秋名山违章图集💊", "😶弯的four"]
        } else {
            tagStrs = [String.trans_tagAll, "Classic👏", "Oh~👻Interesting", "🤔Indescribable.", "Wonderful🍄"]
        }
        
        makeUI()
    }
    
    func animate() {
        guard !animated else { return }
        animated = true
        
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
            self.logoView.transform = .identity
            self.logoView.alpha = 1
            self.addTagView.transform = .identity
            self.addTagView.alpha = 1
            
        }, completion: nil)
        
        let cells = (0..<tagStrs.count).map{ IndexPath(row: $0, section: 0) }
            .flatMap{ tableView.cellForRow(at: $0) }
        
        var delay: TimeInterval = 0
        for cell in cells {
            UIView.animate(withDuration: 0.5, delay: delay, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
                cell.contentView.transform = .identity
                cell.contentView.alpha = 1
            }, completion: nil)
            delay += 0.02
        }
    }
    
    func restore() {
        guard animated else { return }
        animated = false
        
        logoView.transform = CGAffineTransform(translationX: 0, y: -70)
        logoView.alpha = 0
        
        addTagView.transform = CGAffineTransform(translationX: 0, y: -70)
        addTagView.alpha = 0
        
        (0..<tagStrs.count).map{ IndexPath(row: $0, section: 0) }
            .flatMap{ tableView.cellForRow(at: $0) }
            .forEach{
                $0.contentView.transform = CGAffineTransform(translationX: -imageSacle*Config.sideBarWidth, y: 0)
                $0.contentView.alpha = 0
        }
    }
    
    func show() {
        transform = .identity
        alpha = 1
    }
    
    func hide(toLeft: Bool) {
        transform = CGAffineTransform(translationX: toLeft ? -kScreenWidth : kScreenWidth, y: 0)
        alpha = 0
    }
    
    fileprivate func makeUI() {
        
        addSubview(logoView)
        addSubview(addTagView)
        addSubview(tableView)
        
        let originX = kScreenWidth*(0.5-imageSacle/2)
        let containerW = imageSacle * Config.sideBarWidth
        
        logoView.snp.makeConstraints { make in
            make.size.equalTo(50)
            make.top.equalTo(22)
            make.centerX.equalTo(originX+containerW/2)
        }
        
        logoView.transform = CGAffineTransform(translationX: 0, y: -70)
        logoView.alpha = 0
        
        let line = UIView()
        line.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        addTagView.addSubview(line)
        
        let addIcon = UIImageView(image: #imageLiteral(resourceName: "icon_add_tag"))
        addIcon.contentMode = .scaleAspectFit
        
        addTagView.snp.makeConstraints { make in
            make.top.equalTo(logoView.snp.bottom).offset(18)
            make.centerX.equalTo(logoView)
            make.size.equalTo(CGSize(width: containerW, height: 40))
        }
        
        addTagView.transform = CGAffineTransform(translationX: 0, y: -70)
        addTagView.alpha = 0
        
        line.snp.makeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.bottom.equalTo(0)
            make.height.equalTo(0.8)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(addTagView.snp.bottom).offset(6)
            make.left.right.equalTo(addTagView)
            make.bottom.equalTo(0)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tagStrs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TagListCell = tableView.dequeueReusableCell()
        cell.isUserInteractionEnabled = false
        cell.nameField.text = tagStrs[indexPath.item]
        cell.countLabel.text = "\(tagCounts[indexPath.item])"
        
        cell.contentView.transform = CGAffineTransform(translationX: -imageSacle*Config.sideBarWidth, y: 0)
        cell.contentView.alpha = 0

        return cell
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
