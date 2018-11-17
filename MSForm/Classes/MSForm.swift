//
//  MSForm.swift
//  MSForm
//
//  Created by Claudio Madureira on 11/9/18.
//

import UIKit

public protocol MSFormDelegate {
    func completionSuccess(_ form: MSForm, data: MSFormData)
    func completionFailure(_ form: MSForm, error: MSError)
}

@objc public protocol MSFormFieldDelegate {
    func fieldDidChange(_ form: MSForm, at index: Int)
    @objc optional func fieldShouldBeginEditing(_ form: MSForm, at index: Int) -> Bool
    @objc optional func fieldShouldReturn(_ form: MSForm, at index: Int) -> Bool
    @objc optional func fieldDidEndEditing(_ form: MSForm, at index: Int)
    @objc optional func fieldDidBeginEditing(_ form: MSForm, at index: Int)
}

public enum MSFormResponse<Value> {
    case success(MSFormData)
    case failure(MSError)
}

public enum MSLanguageType {
    case pt
    case en
}


typealias MSFormInternalData = [String: (MSTextFieldType, Bool, String?, String?, String?)]

public typealias MSFormData = [String: String?]

public class MSForm: NSObject {
    
    // MARK: - Properties
    
    public var language: MSLanguageType = .pt
    public var passwordLength: Int?
    public var shoudlUseDoneAutomatically: Bool = true
    public var fieldDelegate: MSFormFieldDelegate?
    public var delegate: MSFormDelegate?
    public var data: MSFormData = [:]
    
    var internalData: MSFormInternalData = [:]
    
    public var fields: [Any] = [] {
        didSet {
            for (i, field) in fields.enumerated() {
                let isLast = i == fields.count - 1
                if let field = field as? MSTextField {
                    field.index = i
                    field.ms_delegate = self
                    field.returnKeyType = isLast ? .done : .next
                    if field.isPicker {
                        self.setData(field)
                    }
                }
                if let field = field as? MSTextView {
                    field.index = i
                    field.ms_delegate = self
                    field.returnKeyType = isLast ? .done : .next
                }
            }
        }
    }
    
    // MARK: - Init
    
    convenience init(fields: [Any], passwordLength: Int? = nil) {
        self.init()
        self.fields = fields
        self.passwordLength = passwordLength
        
    }
    
    // MARK: - Local Functions
    
    private func setData(_ field: Any) {
        if let field = field as? MSTextField {
            self.internalData[field.key] = (field.type, field.isOptional, field.text, field.numberMask, field.placeholder)
            self.data[field.key] = field.text
        } else if let field = field as? MSTextView {
            self.internalData[field.key] = (.standard, field.isOptional, field.text, nil, field.placeholder)
            self.data[field.key] = field.text
        }
    }
    
    
    func perfom(completion: ((MSFormResponse<Any>) -> Void)? = nil) {
        var inputTexts: MSFormData = [:]
        let language = self.language
        var password: String?
        var passwordConfirm: String?
        var hasPasswordConfirm: Bool = false
        let method: ((MSFormResponse<Any>) -> Void) = { response in
            guard let delegate = self.delegate else {
                completion?(response)
                return
            }
            switch response {
            case .success(let data):
                delegate.completionSuccess(self, data: data)
            case .failure(let error):
                delegate.completionFailure(self, error: error)
            }
        }
        for key in self.internalData.keys {
            let (type, isOptional, _text, _mask, placeholder) = self.internalData[key]!
            let text = _text ?? ""
            let mask = _mask ?? ""
            if type != .passwordConfirm {
                inputTexts.updateValue(text, forKey: key)
            }
            if !(isOptional && (_text == nil || text.count == 0)) {
                switch type {
                case .email:
                    if !text.isAnEmail {
                        method(.failure(MSForm.getEmailError(language)))
                        return
                    }
                case .number:
                    if !(text.count == mask.count) {
                        method(.failure(MSForm.getNumberError(text, placeholder, language)))
                        return
                    }
                case .password,
                     .passwordConfirm:
                    let passwordCount = text.count
                    if let passwordLength = passwordLength,
                        passwordCount <= passwordLength {
                        method(.failure(MSForm.getPasswordLengthError(passwordLength, language)))
                        return
                    }
                    if type == .password {
                        password = text
                    } else {
                        hasPasswordConfirm = true
                        passwordConfirm = text
                    }
                default:
                    if !(text.count > 0) {
                        method(.failure(MSForm.getEmptyError(placeholder, language)))
                        return
                    }
                }
            }
        }
        if hasPasswordConfirm && password != passwordConfirm {
            method(.failure(MSForm.getPasswordMatchError(language)))
            return
        }
        method(.success(inputTexts))
    }
    
    // MARK: - Class Functions
    
    public class func handle(fields: [MSTextField],
                             passwordLength: Int? = nil,
                             forLanguage language: MSLanguageType = .pt,
                             completion: (MSFormResponse<Any>) -> Void) {
        
        var inputTexts: MSFormData = [:]
        var password: String?
        for field in fields {
            if field.type != .passwordConfirm {
                inputTexts.updateValue(field.text, forKey: field.key)
            }
            if !(field.isOptional && (field.text == nil || field.text?.count == 0)) {
                switch field.type {
                case .email:
                    if !field.isTextAnEmail {
                        completion(.failure(MSForm.getEmailError(language)))
                        return
                    }
                case .number:
                    if !(field.text?.count == field.numberMask?.count) {
                        completion(.failure(MSForm.getNumberError(field.text, field.placeholder, language)))
                        return
                    }
                case .password:
                    let passwordCount = field.text?.count ?? 0
                    if let passwordLength = passwordLength,
                        passwordCount <= passwordLength {
                        completion(.failure(MSForm.getPasswordLengthError(passwordLength, language)))
                        return
                    }
                    password = field.text ?? ""
                case .passwordConfirm:
                    if password != field.text {
                        completion(.failure(MSForm.getPasswordMatchError(language)))
                        return
                    }
                default:
                    if !(field.text?.count ?? 0 > 0) {
                        completion(.failure(MSForm.getEmptyError(field.placeholder, language)))
                        return
                    }
                }
            }
        }
        completion(.success(inputTexts))
    }
    
    public class func handle(fields: [MSTextView],
                             forLanguage language: MSLanguageType = .pt,
                             completion: (MSFormResponse<Any>) -> Void) {
        var inputTexts: MSFormData = [:]
        for field in fields {
            inputTexts.updateValue(field.text, forKey: field.key)
            if !(field.isOptional && (field.text == nil || field.text?.count == 0)) {
                if field.text.isEmpty {
                    let message = "The field".localized(language) +
                        " '\(field.placeholder ?? "Field without placeholder")' " +
                        "must be filled.".localized(language)
                    let error = MSError(code: 6, localizedDescription: message)
                    completion(.failure(error))
                    return
                }
            }
        }
        completion(.success(inputTexts))
    }
    
    public class func handle(fields: [Any],
                             passwordLength: Int? = nil,
                             forLanguage language: MSLanguageType = .pt,
                             completion: (MSFormResponse<Any>) -> Void) {
        var inputTexts: MSFormData = [:]
        var password: String?
        for field in fields {
            if let field = field as? MSTextField {
                if field.type != .passwordConfirm {
                    inputTexts.updateValue(field.text, forKey: field.key)
                }
                if !(field.isOptional && (field.text == nil || field.text?.count == 0)) {
                    switch field.type {
                    case .email:
                        if !field.isTextAnEmail {
                            completion(.failure(MSForm.getEmailError(language)))
                            return
                        }
                    case .number:
                        if !(field.text?.count == field.numberMask?.count) {
                            completion(.failure(MSForm.getNumberError(field.text, field.placeholder, language)))
                            return
                        }
                    case .password:
                        let passwordCount = field.text?.count ?? 0
                        if let passwordLength = passwordLength,
                            passwordCount <= passwordLength {
                            completion(.failure(MSForm.getPasswordLengthError(passwordLength, language)))
                            return
                        }
                        password = field.text
                    case .passwordConfirm:
                        if password != field.text {
                            completion(.failure(MSForm.getPasswordMatchError(language)))
                            return
                        }
                    default:
                        if !(field.text?.count ?? 0 > 0) {
                            completion(.failure(MSForm.getEmptyError(field.placeholder, language)))
                            return
                        }
                    }
                }
            } else if let field = field as? MSTextView {
                inputTexts.updateValue(field.text, forKey: field.key)
                if !(field.isOptional && (field.text == nil || field.text?.count == 0)) {
                    if field.text.isEmpty {
                        let message = "The field".localized(language) +
                            " '\(field.placeholder ?? "Field without placeholder")' " +
                            "must be filled.".localized(language)
                        let error = MSError(code: 6, localizedDescription: message)
                        completion(.failure(error))
                        return
                    }
                }
            } else {
                let error = MSError(code: 7, localizedDescription: "Field not identified in form.".localized(language))
                completion(.failure(error))
                return
            }
        }
        completion(.success(inputTexts))
    }
    
    class func getEmailError(_ language: MSLanguageType) -> MSError {
        return MSError(code: 1,
                       localizedDescription: "Invalid email.".localized(language))
    }
    
    class func getEmptyError(_ placeholder: String?, _ language: MSLanguageType) -> MSError {
        let message = "The field".localized(language) +
            " '\(placeholder ?? "Field without placeholder")' " +
            "must be filled.".localized(language)
        return MSError(code: 5, localizedDescription: message)
    }
    
    class func getPasswordMatchError(_ language: MSLanguageType) -> MSError {
        return MSError(code: 4,
                       localizedDescription: "The passwords doesn't match.".localized(language))
    }
    
    class func getPasswordLengthError(_ passwordLength: Int, _ language: MSLanguageType) -> MSError {
        let message = "The password must have".localized(language) + " \(passwordLength) " + "digits or more.".localized(language)
        return MSError(code: 3, localizedDescription: message)
    }
    
    class func getNumberError(_ text: String?, _ placeholder: String?, _ language: MSLanguageType) -> MSError {
        let message: String
        if text == nil || text == "" {
            message = "The field".localized(language)
                + " '\(placeholder ?? "Field without placeholder")' "
                + "must be filled.".localized(language)
        } else {
            message = "The number of field".localized(language) +
                " '\(placeholder ?? "Field without placeholder")' " +
                "must be filled correctly.".localized(language)
        }
        return MSError(code: 2, localizedDescription: message)
    }

}

// MARK: - MSTextFieldDelegate

extension MSForm: MSTextFieldDelegate {

    public func textFieldDidChange(_ textField: MSTextField) {
        self.setData(textField)
        self.fieldDelegate?.fieldDidChange(self, at: textField.index)
    }
    
    public func textFieldShouldReturn(_ textField: MSTextField) -> Bool {
        let index = textField.index
        if textField == self.fields.last as? MSTextField {
            if self.shoudlUseDoneAutomatically {
                self.perfom()
                return false
            }
        } else {
            if let field = self.fields[index + 1] as? MSTextField {
                DispatchQueue.main.async {
                    field.becomeFirstResponder()
                }
            }
            if let field = self.fields[index + 1] as? MSTextView {
                DispatchQueue.main.async {
                    field.becomeFirstResponder()
                }
            }
        }
        if let delegate = self.fieldDelegate,
            let call = delegate.fieldShouldReturn {
            return call(self, textField.index)
        }
        return true
    }
    
    public func textFieldShouldBeginEditing(_ textField: MSTextField) -> Bool {
        if let delegate = self.fieldDelegate,
            let call = delegate.fieldShouldBeginEditing {
            return call(self, textField.index)
        }
        return true
    }
    
    public func textFieldDidEndEditing(_ textField: MSTextField) {
        self.fieldDelegate?.fieldDidEndEditing?(self, at: textField.index)
    }
    
    public func textFieldDidBeginEditing(_ textField: MSTextField) {
        self.fieldDelegate?.fieldDidBeginEditing?(self, at: textField.index)
    }
    
}

// MARK: - MSTextViewDelegate

extension MSForm: MSTextViewDelegate {
    
    public func textViewDidChange(_ textView: MSTextView) {
        self.setData(textView)
        self.fieldDelegate?.fieldDidChange(self, at: textView.index)
    }
    
    public func textViewShouldReturn(_ textView: MSTextView) -> Bool {
        guard textView == self.fields.last as? MSTextView,
            self.shoudlUseDoneAutomatically else { return true }
        self.perfom()
        return true
    }
    
    public func textViewShouldEndEditing(_ textView: MSTextView) -> Bool {
        if let delegate = self.fieldDelegate,
            let call = delegate.fieldShouldReturn {
            return call(self, textView.index)
        }
        return true
    }
    
    public func textViewShouldBeginEditing(_ textView: MSTextView) -> Bool {
        if let delegate = self.fieldDelegate,
            let call = delegate.fieldShouldBeginEditing {
            return call(self, textView.index)
        }
        return true
    }
    
    public func textViewDidEndEditing(_ textView: MSTextView) {
        self.fieldDelegate?.fieldDidEndEditing?(self, at: textView.index)
    }
    
    public func textViewDidBeginEditing(_ textView: MSTextView) {
        self.fieldDelegate?.fieldDidBeginEditing?(self, at: textView.index)
    }
    
}
