//
//  LinkTextView.swift
//  LinkTextView
//
//  Created by 林達也 on 2016/12/10.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass



private final class TapGestureRecognizer: UILongPressGestureRecognizer {
    override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool {
        if preventedGestureRecognizer.view is UIScrollView {
            return false
        }
        return true
    }
}


public final class LinkTextView: UITextView {
    public enum Text {
        case link(String, Action)
        case string(String)
        
        public typealias Action = () -> Void
    }
    
    fileprivate static let Action = "LinkTextView::Action"
    
    public var textForegroundColor: UIColor? { didSet { updateTexts() } }
    public var textBackgroundColor: UIColor? { didSet { updateTexts() } }
    public var linkForegroundColor: UIColor? { didSet { updateTexts() } }
    public var linkBackgroundColor: UIColor? { didSet { updateTexts() } }
    public var texts: [Text] = [] { didSet { updateTexts() } }
    
    public override var font: UIFont? { didSet { updateTexts() } }
    
    fileprivate var textAttributes: [String: Any?] {
        let font = self.font ?? UIFont.systemFont(ofSize: 17)
        return [
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: textColor ?? .black
        ]
    }
    fileprivate var linkAttributes: [String: Any?] {
        let font = self.font ?? UIFont.systemFont(ofSize: 17)
        return [
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: UIColor.blue,
            NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue,
            NSBackgroundColorAttributeName: nil
        ]
    }
    fileprivate var selectedLinkAttributes: [String: Any?] {
        var attributes = linkAttributes
        attributes[NSBackgroundColorAttributeName] = UIColor.black.withAlphaComponent(0.2)
        return attributes
    }
    
    fileprivate var selected: (action: Text.Action, range: NSRange)?
    
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
            for (key, val) in self.textAttributes {
                if let val = val {
                    attributes[key] = val
                }
            }
            return attributes
        }()
        let linkAttributes: [String: Any] = {
            var attributes: [String: Any] = [:]
            for (key, val) in self.linkAttributes {
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
        case .changed:()
        case .ended:
            tapEnded(gesture)
        default:
            tapCancelled(gesture)
        }
    }
    
    private func tapBegan(_ gesture: UIGestureRecognizer) {
        if let (action, range) = lookupAction(gesture) {
            selected = (action, range)
            attributedText = attributedText(with: range, highlighted: true)
            setNeedsDisplay()
        }
    }
    
    private func tapEnded(_ gesture: UIGestureRecognizer) {
        if let (action, range) = selected {
            attributedText = attributedText(with: range, highlighted: false)
            setNeedsDisplay()
            selected = nil
            action()
        }
    }
    
    private func tapCancelled(_ gesture: UIGestureRecognizer) {
        if let (_, range) = selected {
            attributedText = attributedText(with: range, highlighted: false)
            setNeedsDisplay()
            selected = nil
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
        for (key, val) in (highlighted ? selectedLinkAttributes : linkAttributes) {
            attributes[key] = val
        }
        string.setAttributes(attributes, range: range)
        return string
    }
}
