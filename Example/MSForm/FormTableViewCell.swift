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
    
    var indexPath: IndexPath! {
        didSet {
            self.textField.numberMask = nil
            self.textField.isOptional = false
            self.textField.index = indexPath.row
            switch indexPath.row {
            case 0:
                self.textField.setType(.email)
                self.textField.key = "email"
                self.textField.placeholder = "Email"
            case 1:
                self.textField.setType(.number)
                self.textField.key = "phone"
                self.textField.numberMask = "(##) # ####-####"
                self.textField.placeholder = "Phone"
                self.textField.isOptional = true
            case 2:
                self.textField.setType(.capitalized)
                self.textField.key = "name"
                self.textField.placeholder = "Name"
            case 3:
                self.textField.setType(.password)
                self.textField.key = "password"
                self.textField.placeholder = "Password"
            default:
                self.textField.setType(.passwordConfirm)
                self.textField.placeholder = "Password confirm"
            }
        }
    }
    
    
    func setInfo(_ indexPath: IndexPath) {
        self.indexPath = indexPath
    }
    
    
    

}
