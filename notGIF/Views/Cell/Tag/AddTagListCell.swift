//
//  AddTagListCell.swift
//  notGIF
//
//  Created by Atuooo on 17/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

class AddTagListCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        nameLabel.text = nil
        countLabel.text = nil
    }
    
    public func configure(with tag: Tag, isChoosed: Bool) {
        
        nameLabel.text = tag.localNameStr
        countLabel.text = "\(tag.gifs.count)"
        
        if tag.id == Config.defaultTagID {
            accessoryType = .none
            nameLabel.textColor = UIColor.lightText
            countLabel.textColor = UIColor.lightText
        } else {
            accessoryType = isChoosed ? .checkmark : .none
            nameLabel.textColor = .black
            countLabel.textColor = .black
        }
    }
}
