//
//  FormTableViewController.swift
//  MSForm_Example
//
//  Created by Claudio Madureira on 11/16/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

import MSForm

class FormTableViewController: UITableViewController, MSFormDelegate {

    var fields: [MSTextField] = []
    var form: MSForm = MSForm()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.form.language = .en
        self.form.passwordLength = 6
        self.form.delegate = self
        self.tableView.separatorColor = .clear
        self.tableView.separatorStyle = .none
    }
    
    func setTextField(_ textField: MSTextField, indexPath: IndexPath) {
        textField.numberMask = nil
        textField.isOptional = false
        textField.stringPickerData = nil
        textField.index = indexPath.row
        switch indexPath.row {
        case 0:
            textField.setType(.email)
            textField.key = "email"
            textField.placeholder = "Email"
        case 1:
            textField.setType(.number)
            textField.key = "phone"
            textField.numberMask = "(##) # ####-####"
            textField.placeholder = "Phone"
            textField.isOptional = true
        case 2:
            textField.setType(.stringPicker)
            textField.key = "sex"
            textField.placeholder = "Sex"
            textField.stringPickerData = ["Homem", "Mulher", "Outro"]
        case 3:
            textField.setType(.password)
            textField.key = "password"
            textField.placeholder = "Password"
        default:
            textField.setType(.passwordConfirm)
            textField.key = "passwordConfirm"
            textField.placeholder = "Password confirm"
        }
        let fieldsCount = 5
        self.fields.addField(field: textField, maxLength: fieldsCount)
        self.form.fields = self.fields
        textField.returnKeyType = indexPath.row == fieldsCount - 1 ? .done : .next
        let data = self.form.data
        textField.setValueFrom(data: data)
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        
        return 5
    }
    
    override func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 250
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FormTableViewCell
        self.setTextField(cell.textField, indexPath: indexPath)
        return cell
    }
    
    // MARK: - MSFormDelegate
    
    func completionSuccess(_ form: MSForm, data: MSFormData) {
        print("Data: ", data.removeNilValues())
    }
    
    func completionFailure(_ form: MSForm, error: MSError) {
        print("Error: ", error.localizedDescription)
    }

}
