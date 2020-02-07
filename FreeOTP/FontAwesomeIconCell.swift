//
//  FontAwesomeIconCell.swift
//  FreeOTP
//
//  Created by Justin Stephenson on 2/12/20.
//  Copyright © 2020 Fedora Project. All rights reserved.
//

import UIKit

class FontAwesomeIconCell: UICollectionViewCell {

    @IBOutlet weak var iconImage: UIImageView!

    override var isSelected: Bool {
        didSet {
            self.layer.borderWidth = 3.0
            self.layer.borderColor = isSelected ? UIColor.blue.cgColor : UIColor.clear.cgColor
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconImage.backgroundColor = UIColor.clear
    }
}
