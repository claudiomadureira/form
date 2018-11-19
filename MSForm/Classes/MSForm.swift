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

struct InternalData {
    let index: Int
    let type: MSTextFieldType
    let isOptional: Bool
    let text: String?
    let placeholder: String?
    let mask: String?
}

typealias MSFormInternalData = [String: InternalData]

public typealias MSFormData = [String: String?]

public class MSForm: NSObject {
    
    // MARK: - Properties
    
    public var language: MSLanguageType = .pt
    public var passwordLength: Int?
    public var shoudlUseDoneAutomatically: Bool = true
    public var fieldDelegate: MSFormFieldDelegate?
    public var delegate: MSFormDelegate?
    public var data: MSFormData = [:]
    
    public var fields: [Any] = [] {
        didSet {
            for (i, field) in fields.enumerated() {
                let isLast = i == fields.count - 1
                if let field = field as? MSTextField {
                    field.ms_delegate = self
                    field.index = i
                    field.returnKeyType = isLast ? .done : .next
                }
                if let field = field as? MSTextView {
                    field.index = i
                    field.ms_delegate = self
                    field.returnKeyType = isLast ? .done : .next
                }
                self.setData(field)
            }
        }
    }
    
    private var internalData: MSFormInternalData = [:]
    
    // MARK: - Init
    
    convenience init(fields: [Any], passwordLength: Int? = nil) {
        self.init()
        self.fields = fields
        self.passwordLength = passwordLength
        
    }
    
    // MARK: - Local Functions
    
    fileprivate func setData(_ field: Any) {
        if let field = field as? MSTextField {
            let data = InternalData(index: field.index,
                                    type: field.type,
                                    isOptional: field.isOptional,
                                    text: field.text,
                                    placeholder: field.placeholder,
                                    mask: field.numberMask)
            self.internalData[field.key] = data
            self.data[field.key] = field.text
        } else if let field = field as? MSTextView {
            let text = field.text != field.placeholder ? field.text : nil
            let data = InternalData(index: field.index,
                                    type: .standard,
                                    isOptional: field.isOptional,
                                    text: text,
                                    placeholder: field.placeholder,
                                    mask: nil)
            self.internalData[field.key] = data
            self.data[field.key] = text
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
        var ordernedArray: [(String, Int, MSTextFieldType, Bool, String?, String?, String?)] = []
        for key in self.internalData.keys {
            let data = self.internalData[key]!
            ordernedArray.append((key, data.index, data.type, data.isOptional, data.text, data.mask, data.placeholder))
        }
        ordernedArray.sort(by: { $0.1 < $1.1 })
        for tuple in ordernedArray {
            let (key, _, type, isOptional, text, mask, placeholder) = tuple
            if let error = MSForm.getErrorTextField(isOptional,
                                                    type,
                                                    text ?? "",
                                                    placeholder,
                                                    mask ?? "",
                                                    language,
                                                    passwordLength) {
                method(.failure(error))
                return
            }
            if type != .passwordConfirm {
                inputTexts.updateValue(text, forKey: key)
            }
            if type == .password {
                password = text
            } else if type == .passwordConfirm {
                hasPasswordConfirm = true
                passwordConfirm = text
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
        var passwordConfirm: String?
        var hasPasswordConfirm: Bool = false
        for field in fields {
            if let error = MSForm.getErrorTextField(field.isOptional,
                                                    field.type,
                                                    field.text ?? "",
                                                    field.placeholder,
                                                    field.numberMask ?? "",
                                                    language,
                                                    passwordLength) {
                completion(.failure(error))
                return
            }
            if field.type != .passwordConfirm {
                inputTexts.updateValue(field.text, forKey: field.key)
            }
            if field.type == .password {
                password = field.text
            } else if field.type == .passwordConfirm {
                hasPasswordConfirm = true
                passwordConfirm = field.text
            }
        }
        if hasPasswordConfirm && password != passwordConfirm {
            completion(.failure(MSForm.getPasswordMatchError(language)))
            return
        }
        completion(.success(inputTexts))
    }
    
    public class func handle(fields: [MSTextView],
                             forLanguage language: MSLanguageType = .pt,
                             completion: (MSFormResponse<Any>) -> Void) {
        
        var inputTexts: MSFormData = [:]
        for field in fields {
            let text = field.text != field.placeholder ? field.text! : ""
            let isOptional = field.isOptional
            let placeholder = field.placeholder
            if let error = MSForm.getErrorTextView(isOptional,
                                                   text,
                                                   placeholder,
                                                   language) {
                completion(.failure(error))
                return
            }
            inputTexts.updateValue(text, forKey: field.key)
        }
        completion(.success(inputTexts))
    }
    
    public class func handle(fields: [Any],
                             passwordLength: Int? = nil,
                             forLanguage language: MSLanguageType = .pt,
                             completion: (MSFormResponse<Any>) -> Void) {
        
        var inputTexts: MSFormData = [:]
        var password: String?
        var passwordConfirm: String?
        var hasPasswordConfirm: Bool = false
        for field in fields {
            if let field = field as? MSTextField {
                if let error = MSForm.getErrorTextField(field.isOptional,
                                                        field.type,
                                                        field.text ?? "",
                                                        field.placeholder ?? "",
                                                        field.numberMask ?? "",
                                                        language,
                                                        passwordLength) {
                    completion(.failure(error))
                    return
                }
                if field.type != .passwordConfirm {
                    inputTexts.updateValue(field.text, forKey: field.key)
                }
                if field.type == .password {
                    password = field.text
                } else if field.type == .passwordConfirm {
                    hasPasswordConfirm = true
                    passwordConfirm = field.text
                }
            } else if let field = field as? MSTextView {
                inputTexts.updateValue(field.text, forKey: field.key)
                if let error = MSForm.getErrorTextView(field.isOptional,
                                                       field.text,
                                                       field.placeholder,
                                                       language) {
                    completion(.failure(error))
                    return
                }
            } else {
                let error = MSError(code: 7, localizedDescription: "Field not identified in form.".localized(language))
                completion(.failure(error))
                return
            }
        }
        if hasPasswordConfirm && password != passwordConfirm {
            completion(.failure(MSForm.getPasswordMatchError(language)))
            return
        }
        completion(.success(inputTexts))
    }
    
    class func getErrorTextView(_ isOptional: Bool,
                                _ text: String,
                                _ placeholder: String?,
                                _ language: MSLanguageType) -> MSError? {
        if !(isOptional && (text.clear(occurences: [" "]).count == 0)) {
            if text.isEmpty {
                let message = "The field".localized(language) +
                    " '\(placeholder ?? "Field without placeholder")' " +
                    "must be filled.".localized(language)
                return MSError(code: 6, localizedDescription: message)
            }
        }
        return nil
    }
    
    class func getErrorTextField(_ isOptional: Bool,
                                _ type: MSTextFieldType,
                                _ text: String,
                                _ placeholder: String?,
                                _ mask: String,
                                _ language: MSLanguageType,
                                _ passwordLength: Int?) -> MSError? {
        
        if !(isOptional && text.count == 0) {
            switch type {
            case .email:
                if !text.isAnEmail {
                    return MSForm.getEmailError(language)
                }
            case .number:
                if !(text.count == mask.count) {
                    return MSForm.getNumberError(text, placeholder, language)
                }
            case .password,
                 .passwordConfirm:
                let passwordCount = text.count
                if let passwordLength = passwordLength,
                    passwordCount <= passwordLength {
                    return MSForm.getPasswordLengthError(passwordLength, language)
                }
            default:
                if !(text.count > 0) {
                    return MSForm.getEmptyError(placeholder, language)
                }
            }
        }
        return nil
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
