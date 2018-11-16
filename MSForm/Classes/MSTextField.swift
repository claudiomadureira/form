//
//  MSTextField.swift
//  MSForm
//
//  Created by Claudio Madureira on 11/6/18.
//

import UIKit

public protocol MSTextFieldDelegate {
    func textFieldDidChange(_ textField: MSTextField)
    func textFieldShouldReturn(_ textField: MSTextField) -> Bool
    func textFieldShouldBeginEditing(_ textField: MSTextField) -> Bool
    func textFieldDidEndEditing(_ textField: MSTextField)
    func textFieldDidBeginEditing(_ textField: MSTextField)
}

public enum MSTextFieldType: Int {
    case standard = -1
    case capitalized = 0
    case email = 1
    case number = 2
    case password = 3
    case passwordConfirm = 4
    case datePicker = 5
    case stringPicker = 6
}


@IBDesignable
public class MSTextField: UITextField, UITextFieldDelegate {
    
    // MARK: - Properties
    
    override public var text: String? {
        didSet {
            self.ms_delegate?.textFieldDidChange(self)
        }
    }
    
    public var index: Int = 0

    @IBInspectable
    public var key: String = "default_key"
    
    @IBInspectable
    public var numberMask: String?
    
    @IBInspectable
    public var changeAutomatically: Bool = true
    
    @IBInspectable
    public var isOptional: Bool = false
    
    @IBInspectable
    private var _type: Int = -1 {
        didSet {
            self.setupKeyboardByType()
            if self.isPicker {
                switch self.type {
                case .datePicker:
                    self.datePicker = UIDatePicker()
                case .stringPicker:
                    self.stringPicker = UIPickerView()
                default:
                    return
                }
                inputAccessoryView = toolbar
                self.setupArrowFrame()
                self.addSubview(iconArrow)
            } else {
                inputAccessoryView = nil
                self.iconArrow.removeFromSuperview()
            }
        }
    }
    
    public var type: MSTextFieldType {
        let types: [MSTextFieldType] = [.standard,
                                        .email,
                                        .number,
                                        .password,
                                        .passwordConfirm,
                                        .datePicker,
                                        .stringPicker]
        for type in types {
            if self._type == type.rawValue {
                return type
            }
        }
        return .standard
    }
    
    private var isPicker: Bool {
        let type = self.type
        return type == .datePicker || type == .stringPicker
    }
    
    public var ms_delegate: MSTextFieldDelegate?
    
    public var isTextAnEmail: Bool {
        guard let string = self.text else { return false }
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let range = string.range(of: emailRegEx, options: .regularExpression)
        return range != nil
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.setupKeyboardByType()
        self.delegate = self
        self.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        if self.isPicker {
            self.setupArrowFrame()
        }
    }
    
    public var isInputValid: Bool {
        switch self.type {
        case .email:
            return self.isTextAnEmail
        case .number:
            return self.numberMask?.count == self.text?.count
        default:
            return self.text?.count != 0 && self.text != nil
        }
    }
    
    // MARK: - Local Functions
    
    public func setType(_ type: MSTextFieldType) {
        self._type = type.rawValue
    }

    private func setupKeyboardByType() {
        switch self.type {
        case .password,
             .passwordConfirm:
            self.isSecureTextEntry = true
            self.keyboardType = .default
        case .email:
            self.isSecureTextEntry = false
            self.keyboardType = .emailAddress
        case .number:
            self.isSecureTextEntry = false
            self.keyboardType = .decimalPad
        default:
            self.isSecureTextEntry = false
            self.keyboardType = .default
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        self.ms_delegate?.textFieldDidChange(self)
    }
    
    // MARK: - UITextFieldDelegate

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let delegate = self.ms_delegate {
            return delegate.textFieldShouldReturn(self)
        }
        return true
    }
    
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if self.isPicker {
            self.rotateArrow(to: CGFloat.pi)
        }
        if let delegate = self.ms_delegate {
            return delegate.textFieldShouldBeginEditing(self)
        }
        return true
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        if self.isPicker {
            self.rotateArrow(to: 0)
        }
        self.ms_delegate?.textFieldDidEndEditing(self)
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        self.ms_delegate?.textFieldDidBeginEditing(self)
    }
    
    public func textField(_ textField: UITextField,
                          shouldChangeCharactersIn range: NSRange,
                          replacementString string: String) -> Bool {
        
        switch self.type {
        case .number:
            return self.applyNumberMask(textField,
                                        shouldChangeCharactersIn: range,
                                        replacementString: string)
        case .email:
            return self.applyEmailShouldChange(textField,
                                               shouldChangeCharactersIn: range,
                                               replacementString: string)
        default:
            return true
        }
    }
    
    private func applyEmailShouldChange(_ textField: UITextField,
                                        shouldChangeCharactersIn range: NSRange,
                                        replacementString string: String) -> Bool {
        
        return string != " " || string.count > 1 || string == ""
    }
    
    private func applyNumberMask(_ textField: UITextField,
                                 shouldChangeCharactersIn range: NSRange,
                                 replacementString string: String) -> Bool {
        
        guard let numberMask = self.numberMask else { return true }
        if string == "" {
            if var text = textField.text,
                text.count > 0 {
                text.removeLast()
                var last = text.last
                while (!self.isNumber(last ?? "1")) {
                    text.removeLast()
                    last = text.last
                }
                self.text = text
            }
            return false
        }
        let currentTextDigited: String = textField.text! + string
        
        if currentTextDigited.count > numberMask.count {
            if self.changeAutomatically {
                let _ = self.ms_delegate?.textFieldShouldReturn(self)
            }
            return false
        }
        var last = 0
        var returnText = ""
        var needAppend = false
        var i = 0
        let maskArray = Array(numberMask)
        for char in currentTextDigited {
            let currCharMask = maskArray[i]
            if self.isNumber(char) && currCharMask == "#" {
                returnText.append(char)
            } else {
                if currCharMask == "#" {
                    break
                }
                if isNumber(char) && currCharMask != char {
                    needAppend = true
                }
                returnText.append(currCharMask)
            }
            last = i
            i += 1
        }
        
        i = last + 1
        for i in (last + 1)..<numberMask.count {
            let currCharMask = maskArray[i]
            if (currCharMask != "#") {
                returnText.append(currCharMask)
            }
            if (currCharMask == "#") {
                break
            }
        }
        if needAppend {
            returnText.append(string)
        }
        self.text = returnText
        if returnText.count == numberMask.count {
            if self.changeAutomatically {
                let _ = self.ms_delegate?.textFieldShouldReturn(self)
            }
        }
        return false
    }
    
    private func isNumber(_ char: Character) -> Bool {
        for num in 0..<10 {
            if String(char) == String(num) {
                return true
            }
        }
        return false
    }
    
    // MARK: - Pickers
    
    lazy var iconArrow: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        let icon = UIImage.getFrom(customClass: MSTextField.self, nameResource: "iconArrowPicker", type: ".png")
        view.image = icon
        return view
    }()
    
    // For DatePicker
    open var dateFormatter = DateFormatter()
    open var dateDidChange: ((Date) -> Void)?
    
    open var datePicker: UIDatePicker? {
        get {
            return self.inputView as? UIDatePicker
        }
        set {
            inputView = newValue
            dateFormatter.dateFormat = "MM/dd/YYYY"
        }
    }
    
    // For String Picker
    
    open var stringPickerData: [String]?
    open var stringDidChange: ((Int) -> Void)?
    
    open var pickerRow: UILabel {
        let pickerLabel = UILabel()
        pickerLabel.textColor = .black
        pickerLabel.font = UIFont(name: "HelveticaNeue", size: 20)
        pickerLabel.textAlignment = .center
        pickerLabel.sizeToFit()
        return pickerLabel
    }
    
    open var stringPicker: UIPickerView? {
        get {
            return self.inputView as? UIPickerView
        }
        set(picker) {
            if let picker = picker {
                picker.delegate = self
                picker.dataSource = self
            }
            inputView = picker
        }
    }
    
    open var toolbar: UIToolbar {
        let toolBar = UIToolbar()
        toolBar.barStyle = .default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor.blue
        toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done,
                                         target: self,
                                         action: #selector(MSTextField.doneAction))
        
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                          target: nil,
                                          action: nil)
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel,
                                           target: self,
                                           action: #selector(MSTextField.cancelAction))
        
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        inputAccessoryView = toolBar
        return toolBar
    }
    
    @objc func doneAction() {
        switch self.type {
        case .datePicker:
            let date = datePicker!.date
            self.text = dateFormatter.string(from: date)
            dateDidChange?(date)
        case .stringPicker:
            let row = stringPicker!.selectedRow(inComponent: 0)
            self.text = stringPickerData![row]
            stringDidChange?(row)
        default:
            return
        }
        let _ = self.ms_delegate?.textFieldShouldReturn(self)
        resignFirstResponder()
    }
    
    @objc func cancelAction() {
        resignFirstResponder()
    }
    
    fileprivate func rotateArrow(to angle: CGFloat) {
        UIView.animate(withDuration: 0.3, animations: {
            self.iconArrow.transform = CGAffineTransform(rotationAngle: angle)
        })
    }
    
    private func setupArrowFrame() {
        let sizeSelf = self.frame.size
        let point = CGPoint(x: sizeSelf.width, y: sizeSelf.height * 0.375)
        let size = CGSize(width: 40, height: sizeSelf.height * 0.25)
        let frame = CGRect(x: point.x - size.width, y: point.y, width: size.width, height: size.height)
        self.iconArrow.frame = frame
    }
    
    
}

//MARK: UIPickerViewDelegate
extension MSTextField: UIPickerViewDelegate, UIPickerViewDataSource {
    
    open func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return stringPickerData?.count ?? 0
    }
    
    open func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    open func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = pickerRow
        label.text = stringPickerData![row]
        return label
    }
    
}

