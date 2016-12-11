//
//  LinkTextView.swift
//  LinkTextView
//
//  Created by 林達也 on 2016/12/10.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass


public final class LinkTextView: UITextView {
    public enum Text {
        case link(String, Action)
        case string(String)
        
        public typealias Action = () -> Void
    }
    
    fileprivate static let Action = "LinkTextView::Action"
    
    public var texts: [Text] = [] { didSet { updateTexts() } }
    
    public override var font: UIFont? {
        didSet {
            if textAttributes == nil || linkAttributes == nil {
                updateTexts()
            }
        }
    }
    
    public var textAttributes: [String: Any?]?
    public var linkAttributes: [String: Any?]?
    public var selectedLinkAttributes: [String: Any?]?
    
    fileprivate var _textAttributes: [String: Any?] {
        return textAttributes ?? [
            NSFontAttributeName: font ?? UIFont.systemFont(ofSize: 17),
            NSForegroundColorAttributeName: textColor ?? .black
        ]
    }
    fileprivate var _linkAttributes: [String: Any?] {
        return linkAttributes ?? [
            NSFontAttributeName: font ?? UIFont.systemFont(ofSize: 17),
            NSForegroundColorAttributeName: UIColor.blue,
            NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
            NSBackgroundColorAttributeName: nil
        ]
    }
    fileprivate var _selectedLinkAttributes: [String: Any?] {
        return selectedLinkAttributes ?? {
            var attributes = linkAttributes ?? _linkAttributes
            attributes[NSBackgroundColorAttributeName] = UIColor.black.withAlphaComponent(0.2)
            return attributes
        }()
    }
    
    fileprivate let validSize = CGSize(width: 44, height: 44)
    fileprivate var selected: (action: Text.Action, range: NSRange, location: CGPoint)?
    
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    private func setup() {
        isEditable = false
        isScrollEnabled = false
        isSelectable = false
        
        addGestureRecognizer({
            let gesture = TapGestureRecognizer(target: self, action: #selector(self.tapAction(_:)))
            gesture.minimumPressDuration = 0.1
            return gesture
            }())
    }
    
    private func updateTexts() {
        guard !texts.isEmpty else { return }
        let string = NSMutableAttributedString()
        let textAttributes: [String: Any] = {
            var attributes: [String: Any] = [:]
            for (key, val) in _textAttributes {
                if let val = val {
                    attributes[key] = val
                }
            }
            return attributes
        }()
        let linkAttributes: [String: Any] = {
            var attributes: [String: Any] = [:]
            for (key, val) in _linkAttributes {
                if let val = val {
                    attributes[key] = val
                }
            }
            return attributes
        }()
        for t in texts {
            switch t {
            case .string(let str):
                string.append(NSAttributedString(string: str, attributes: textAttributes))
            case .link(let str, let action):
                var attributes = linkAttributes
                attributes[LinkTextView.Action] = action
                string.append(NSAttributedString(string: str, attributes: attributes))
            }
        }
        attributedText = string
    }
}

extension LinkTextView {
    @objc
    fileprivate func tapAction(_ gesture: UIGestureRecognizer) {
        switch gesture.state {
        case .began:
            tapBegan(gesture)
        case .changed:
            tapMoved(gesture)
        case .ended:
            tapEnded(gesture)
        default:
            tapCancelled(gesture)
        }
    }
    
    private func tapBegan(_ gesture: UIGestureRecognizer) {
        if let (action, range) = lookupAction(gesture) {
            selected = (action, range, gesture.location(in: window))
            attributedText = attributedText(with: range, highlighted: true)
            setNeedsDisplay()
        }
    }
    
    private func tapEnded(_ gesture: UIGestureRecognizer) {
        if let (action, range, _) = selected {
            attributedText = attributedText(with: range, highlighted: false)
            setNeedsDisplay()
            selected = nil
            action()
        }
    }
    
    private func tapCancelled(_ gesture: UIGestureRecognizer) {
        if let (_, range, _) = selected {
            attributedText = attributedText(with: range, highlighted: false)
            setNeedsDisplay()
            selected = nil
        }
    }
    
    private func tapMoved(_ gesture: UIGestureRecognizer) {
        if let (_, _, location) = selected {
            let current = gesture.location(in: window)
            let diff = (x: abs(current.x - location.x), y: abs(current.y - location.y))
            if diff.x > validSize.width || diff.y > validSize.height {
                gesture.state = .cancelled
            }
        }
    }
    
    private func lookupAction(_ gesture: UIGestureRecognizer) -> (Text.Action, NSRange)? {
        var location = gesture.location(in: self)
        location.y -= textContainerInset.top
        location.x -= textContainerInset.left
        var distance: CGFloat = -1
        let characterIndex = layoutManager.characterIndex(
            for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: &distance)
        if distance >= 1 {
            return nil
        }
        var range = NSMakeRange(0, 0)
        if let action = attributedText.attribute(
            LinkTextView.Action, at: characterIndex, effectiveRange: &range) as? Text.Action {
            return (action, range)
        }
        return nil
    }
    
    private func attributedText(with range: NSRange, highlighted: Bool) -> NSAttributedString {
        var attributes = attributedText.attributes(at: range.location, effectiveRange: nil)
        let string = attributedText.mutableCopy() as! NSMutableAttributedString
        for (key, val) in (highlighted ? _selectedLinkAttributes : _linkAttributes) {
            attributes[key] = val
        }
        string.setAttributes(attributes, range: range)
        return string
    }
}


private final class TapGestureRecognizer: UILongPressGestureRecognizer {
    override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool {
        if preventedGestureRecognizer.view is UIScrollView {
            return false
        }
        return true
    }
}
