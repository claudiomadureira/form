//
//  MSForm.swift
//  MSForm
//
//  Created by Claudio Madureira on 11/9/18.
//

import UIKit

public protocol MSFormDelegate {
    func completionSuccess(_ form: MSForm, data: [String: String?])
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
    case success([String: String?])
    case failure(MSError)
}

public enum MSLanguageType {
    case pt
    case en
}

public class MSForm: NSObject {
    
    // MARK: - Properties
    
    public var language: MSLanguageType = .pt
    public var fields: [Any] = []
    public var passwordLength: Int?
    public var shoudlUseDoneAutomatically: Bool = true
    public var fieldDelegate: MSFormFieldDelegate?
    public var delegate: MSFormDelegate?
    
    // MARK: - Init
    
    public required init(fields: [Any], passwordLength: Int? = nil) {
        super.init()
        self.fields = fields
        self.passwordLength = passwordLength
        for (i, field) in fields.enumerated() {
            let isLast = i == fields.count - 1
            if let field = field as? MSTextField {
                field.index = i
                field.ms_delegate = self
                field.returnKeyType = isLast ? .done : .next
            }
            if let field = field as? MSTextView {
                field.index = i
                field.ms_delegate = self
                field.returnKeyType = isLast ? .done : .next
            }
        }
    }
    
    // MARK: - Local Functions
    
    func perfom(completion: ((MSFormResponse<Any>) -> Void)? = nil) {
        if let fields = self.fields as? [MSTextField] {
            MSForm.handle(fields: fields, passwordLength: passwordLength, forLanguage: self.language, completion: { response in
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
            })
        } else if let fields = self.fields as? [MSTextView] {
            MSForm.handle(fields: fields, forLanguage: self.language, completion: { response in
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
            })
        } else {
            MSForm.handle(fields: fields, passwordLength: passwordLength, forLanguage: self.language, completion: { response in
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
            })
        }
    }
    
    // MARK: - Class Functions
    
    public class func handle(fields: [MSTextField],
                             passwordLength: Int? = nil,
                             forLanguage language: MSLanguageType = .pt,
                             completion: (MSFormResponse<Any>) -> Void) {
        var inputTexts: [String: String?] = [:]
        var password: String?
        for field in fields {
            if field.type != .passwordConfirm {
                inputTexts.updateValue(field.text, forKey: field.key)
            }
            if !(field.isOptional && (field.text == nil || field.text?.count == 0)) {
                switch field.type {
                case .email:
                    if !field.isTextAnEmail {
                        let error = MSError(code: 1,
                                            localizedDescription: "Invalid email.".localized(language))
                        completion(.failure(error))
                        return
                    }
                case .number:
                    if !(field.text?.count == field.numberMask?.count) {
                        let message: String
                        if field.text == nil || field.text == "" {
                            message = "The field".localized(language) + " '\(field.placeholder ?? "Field without placeholder")' " + "must be filled.".localized(language)
                        } else {
                            message = "The number of field".localized(language) +
                                " '\(field.placeholder ?? "Field without placeholder")' " +
                                "must be filled correctly.".localized(language)
                        }
                        let error = MSError(code: 2, localizedDescription: message)
                        completion(.failure(error))
                        return
                    }
                case .password:
                    let passwordCount = field.text?.count
                    if passwordCount != nil,
                        passwordCount == passwordLength {
                        let message = "The password must have".localized(language) + " \(passwordLength!) " + "or more.".localized(language)
                        let error = MSError(code: 3, localizedDescription: message)
                        completion(.failure(error))
                        return
                    }
                    password = field.text
                case .passwordConfirm:
                    if password != field.text {
                        let error = MSError(code: 4, localizedDescription: "The passwords doesn't match.".localized(language))
                        completion(.failure(error))
                        return
                    }
                default:
                    if !(field.text?.count ?? 0 > 0) {
                        let message = "The field".localized(language) +
                            " '\(field.placeholder ?? "Field without placeholder")' " +
                            "must be filled.".localized(language)
                        let error = MSError(code: 5, localizedDescription: message)
                        completion(.failure(error))
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
        var inputTexts: [String: String?] = [:]
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
        var inputTexts: [String: String?] = [:]
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
                            let error = MSError(code: 1,
                                                localizedDescription: "Invalid email.".localized(language))
                            completion(.failure(error))
                            return
                        }
                    case .number:
                        if !(field.text?.count == field.numberMask?.count) {
                            let message: String
                            if field.text == nil || field.text == "" {
                                message = "The field".localized(language) + " '\(field.placeholder ?? "Field without placeholder")' " + "must be filled.".localized(language)
                            } else {
                                message = "The number of field".localized(language) +
                                    " '\(field.placeholder ?? "Field without placeholder")' " +
                                    "must be filled correctly.".localized(language)
                            }
                            let error = MSError(code: 2, localizedDescription: message)
                            completion(.failure(error))
                            return
                        }
                    case .password:
                        let passwordCount = field.text?.count
                        if passwordCount != nil,
                            passwordCount == passwordLength {
                            let message = "The password must have".localized(language) + " \(passwordLength!) " + "or more.".localized(language)
                            let error = MSError(code: 3, localizedDescription: message)
                            completion(.failure(error))
                            return
                        }
                        password = field.text
                    case .passwordConfirm:
                        if password != field.text {
                            let error = MSError(code: 4, localizedDescription: "The passwords doesn't match.".localized(language))
                            completion(.failure(error))
                            return
                        }
                    default:
                        if !(field.text?.count ?? 0 > 0) {
                            let message = "The field".localized(language) +
                                " '\(field.placeholder ?? "Field without placeholder")' " +
                                "must be filled.".localized(language)
                            let error = MSError(code: 5, localizedDescription: message)
                            completion(.failure(error))
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

}

// MARK: - MSTextFieldDelegate

extension MSForm: MSTextFieldDelegate {

    public func textFieldDidChange(_ textField: MSTextField) {
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
