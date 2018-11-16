//
//  ViewController.swift
//  MSForm
//
//  Created by Cláudio Madureira on 11/06/2018.
//  Copyright (c) 2018 Cláudio Madureira. All rights reserved.
//

import UIKit

import MSForm

class ViewController: UIViewController, MSFormDelegate, MSFormFieldDelegate {
    
    @IBOutlet var fields: [Any]!
    
    var form: MSForm!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let sexField = fields.first as? MSTextField
        sexField?.setType(.stringPicker)
        sexField?.stringPickerData = ["Homem", "Mulher"]
        let form = MSForm(fields: self.fields, passwordLength: 6)
        form.language = .en
        form.fieldDelegate = self
        form.delegate = self
        self.form = form
    }
    
    // MARK: - MSFormFieldDelegate
    
    func fieldDidChange(_ form: MSForm, at index: Int) {
        // ...
    }
    
    func fieldShouldBeginEditing(_ form: MSForm, at index: Int) -> Bool {
        return true
    }
    
    func fieldShouldReturn(_ form: MSForm, at index: Int) -> Bool {
        return true
    }
    
    func fieldDidEndEditing(_ form: MSForm, at index: Int) {
        // ...
    }
    
    func fieldDidBeginEditing(_ form: MSForm, at index: Int) {
        // ...
    }
    
    // MARK: - MSFormDelegate
    
    func completionSuccess(_ form: MSForm, data: [String : String?]) {
        print("Data: ", data.removeNilValues())
    }
    
    func completionFailure(_ form: MSForm, error: MSError) {
        let alert = UIAlertController(title: "Info", message: error.localizedDescription, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }

}

