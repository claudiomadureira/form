//
//  FormTableViewCell.swift
//  MSForm_Example
//
//  Created by Claudio Madureira on 11/16/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

import MSForm

class FormTableViewCell: UITableViewCell {

    @IBOutlet weak var textField: MSTextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }

}
