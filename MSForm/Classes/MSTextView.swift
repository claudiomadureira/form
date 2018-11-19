//
//  MSTextView.swift
//  MSForm
//
//  Created by Claudio Madureira on 11/9/18.
//

import UIKit


public protocol MSTextViewDelegate {
    func textViewDidChange(_ textView: MSTextView)
    func textViewShouldReturn(_ textView: MSTextView) -> Bool
    func textViewShouldEndEditing(_ textView: MSTextView) -> Bool
    func textViewShouldBeginEditing(_ textView: MSTextView) -> Bool
    func textViewDidEndEditing(_ textView: MSTextView)
    func textViewDidBeginEditing(_ textView: MSTextView)
}

@IBDesignable
public class MSTextView: UITextView, UITextViewDelegate {

    // MARK: - Properties
    
    public var ms_delegate: MSTextViewDelegate?
    
    public var index: Int = 0
    
    public override var text: String! {
        didSet {
            if self.text == nil {
                if let attributedPlaceholder = self.attributedPlaceholder {
                    self.attributedText = attributedPlaceholder
                } else {
                    self.text = self.placeholder
                }
            }
            self.setTextColor()
            self.ms_delegate?.textViewDidChange(self)
        }
    }

    @IBInspectable
    public var key: String = "default_key"
    
    @IBInspectable
    public var placeholder: String? {
        didSet {
            if self.text == nil {
                self.text = self.placeholder
                self.setTextColor()
            }
        }
    }
    
    @IBInspectable
    public var attributedPlaceholder: NSAttributedString?
    
    @IBInspectable
    public var isOptional: Bool = false
    
    @IBInspectable
    public var alphaForPlaceholder: CGFloat = 0.2 {
        didSet {
            self.setTextColor()
        }
    }
    
    // MARK: - Lifecycle
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.delegate = self
        if self.text.isEmpty {
            self.text = self.placeholder
        }
    }
    
    // MARK: - Local Functions
    
    func setTextColor() {
        let color: UIColor
        if let attributedPlaceholder = self.attributedPlaceholder,
            let col = attributedPlaceholder.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor {
            color = col
        } else {
            color = self.textColor ?? .black
        }
        let lightAlpha: CGFloat = self.alphaForPlaceholder
        let isPlaceholder = self.text == self.placeholder
        self.textColor = color.withAlphaComponent(isPlaceholder ? lightAlpha : 1)
    }
    
    public func setValueFrom(data: MSFormData) {
        self.text = data[key] ?? self.placeholder
        self.setTextColor()
    }
    
    // MARK: - UITextViewDelegate
    
    public func textViewDidChange(_ textView: UITextView) {
        self.ms_delegate?.textViewDidChange(self)
    }
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        self.ms_delegate?.textViewDidBeginEditing(self)
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        self.ms_delegate?.textViewDidEndEditing(self)
    }
    
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if let delegate = self.ms_delegate {
            return delegate.textViewShouldBeginEditing(self)
        }
        return true
    }
    
    public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        if let delegate = self.ms_delegate {
            return delegate.textViewShouldEndEditing(self)
        }
        return true
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            let _ = self.ms_delegate?.textViewShouldReturn(self)
            return false
        }
        if text.isEmpty {
            if textView.text == self.placeholder {
                return false
            } else if textView.text.isEmpty || textView.text == nil {
                if let attributedPlaceholder = self.attributedPlaceholder {
                    self.attributedText = attributedPlaceholder
                } else {
                    self.text = self.placeholder
                }
                return false
            }
        } else if textView.text == self.placeholder {
            self.text = ""
            return true
        }
        return true
    }
    
    
}
