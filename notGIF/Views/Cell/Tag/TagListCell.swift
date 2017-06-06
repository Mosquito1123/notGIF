//
//  TagListCell.swift
//  notGIF
//
//  Created by Atuooo on 03/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

class TagListCell: UITableViewCell {

    @IBOutlet weak var tagNameLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func prepareForReuse() {
        tagNameLabel.text = nil
        countLabel.text = nil
    }
}
