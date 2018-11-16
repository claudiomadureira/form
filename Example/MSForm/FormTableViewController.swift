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
    var form: MSForm?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorColor = .clear
        self.tableView.separatorStyle = .none
    }
    
    func addInFields(field: MSTextField) {
        self.fields.addField(field: field, maxLength: 5)
        self.form = MSForm(fields: self.fields, passwordLength: 6)
        self.form?.delegate = self
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    override func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FormTableViewCell
        cell.setInfo(indexPath)
        self.addInFields(field: cell.textField)
        return cell
    }
    
    // MARK: - MSFormDelegate
    
    func completionSuccess(_ form: MSForm, data: [String : String?]) {
        print("Data: ", data)
    }
    
    func completionFailure(_ form: MSForm, error: MSError) {
        print("Error: ", error.localizedDescription)
    }

}
