//
//  Extensions.swift
//  MSForm
//
//  Created by Claudio Madureira on 11/6/18.
//

import UIKit


public extension Dictionary {
    
    public func removeNilValues() -> [String: Any] {
        guard let selfDic = self as? [String: Any?] else { return [:] }
        var newDic: [String: Any] = [:]
        for key in selfDic.keys {
            if let value = selfDic[key] {
                newDic[key] = value
            }
        }
        return newDic
    }
}

extension String {
    
    func clear(occurences: [String]) -> String {
        return self.replace(occurences: occurences, with: "")
    }
    
    func replace(occurences: [String], with string: String) -> String {
        var result = self
        for replace in occurences {
            result = result.replacingOccurrences(of: replace, with: string)
        }
        return result
    }
    
    func localized(_ language: MSLanguageType) -> String {
        guard language == .pt else {
            return self
        }
        switch self {
        case "Email": return "Email"
        case "Password": return "Senha"
        case "Ops!": return "Ops!"
        case "Invalid email.": return "Email inválido."
        case "Insert your email for recover your password.": return "Insira seu email para recuperar sua senha."
        case "Cancel": return "Cancelar"
        case "Recover": return "Recuperar"
        case "The field": return "O campo"
        case "must be filled.": return "deve ser preenchido."
        case "digits or more.": return "dígitos ou mais"
        case "The password must have": return "A senha deve ter"
        case "The passwords doesn't match.": return "As senhas nao combinam."
        case "The number of field": return "O número do campo"
        case "must be filled correctly.": return "deve ser preenchido corretamente."
        case "Field not identified in form.": return "Campo não identificado dentro no formulário."
        default: return self
        }
    }
    
}

extension UIImage {
    
    class func getFrom(nameResource: String, type: String) -> UIImage? {
        guard let bundle = Bundle.main.path(forResource: nameResource, ofType: type) else { return nil }
        let url = URL(fileURLWithPath: bundle)
        guard let data = try? Data(contentsOf: url) else { return nil }
        let image = UIImage(data: data)
        return image
    }
    
    class func getFrom(customClass: AnyClass, nameResource: String, type: String) -> UIImage? {
        guard let bundle = Bundle(for: customClass).path(forResource: nameResource, ofType: type) else { return nil }
        let url = URL(fileURLWithPath: bundle)
        guard let data = try? Data(contentsOf: url) else { return nil }
        let image = UIImage(data: data)
        return image
    }
    
}



