//
//  KeyBoardAddition.swift
//  RichTextField
//
//  Created by Joseph Levy on 9/10/23.
//

import SwiftUI

struct KeyBoardToolBar  {
    
    var textView: TextEditorWrapper.MyTextView
    var isBold: Bool = false
    var isItalic: Bool = false
    var isUnderline: Bool = false
    var isStrikethrough: Bool = false
    var isSuperscript: Bool = false
    var isSubscript: Bool = false
    var fontSize: CGFloat = 17
    var textAlignment: NSTextAlignment = .left
    var color : Color = Color(uiColor: .label)
    var background: Color = Color(uiColor: .systemBackground)
    
    var justChanged: Bool = false
}

struct KeyBoardAddition: View {
    @Binding var toolbar: KeyBoardToolBar
    
    private let buttonWidth: CGFloat = 32
    private let buttonHeight: CGFloat = 32
    private let cornerRadius: CGFloat = 6
    private let edgeInsets = EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
    private let selectedColor = UIColor.separator
    private let containerBackgroundColor: UIColor = .systemBackground
    private let toolBarsBackground: UIColor = .systemGroupedBackground
    private let colorConf = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
    private var imageConf: UIImage.SymbolConfiguration {
        UIImage.SymbolConfiguration(pointSize: min(buttonWidth, buttonHeight) * 0.7)
    }
    var attributes: [NSAttributedString.Key : Any] { toolbar.textView.typingAttributes }
    
    func roundedRectangle(_ highlight: Bool = false) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius).fill(Color(highlight ? selectedColor : .clear))
            .frame(width: buttonWidth, height: buttonHeight)
    }
    
    func updateAttributedText(with attributedText: NSAttributedString) {
        let selection = toolbar.textView.selectedRange
        toolbar.textView.updateAttributedText(with: attributedText)
        toolbar.textView.selectedRange = selection
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack (spacing: 1) {
                Group {
                    Button(action: toggleBoldface) { Image(systemName: "bold") }
                        .frame(width: buttonWidth, height: buttonHeight)
                        .background(roundedRectangle(toolbar.isBold))
                    Button(action: toggleItalics) { Image(systemName: "italic") }
                        .frame(width: buttonWidth, height: buttonHeight)
                        .background(roundedRectangle(toolbar.isItalic))
                    Button(action: toggleUnderline) { Image(systemName: "underline") }
                        .frame(width: buttonWidth, height: buttonHeight)
                        .background(roundedRectangle(toolbar.isUnderline))
                    Button(action: toggleStrikethrough) { Image(systemName: "strikethrough") }
                        .frame(width: buttonWidth, height: buttonHeight)
                        .background(roundedRectangle(toolbar.isStrikethrough))
                    Button(action: toggleSuperscript) { Image(systemName: "textformat.superscript") }
                        .frame(width: buttonWidth, height: buttonHeight)
                        .background(roundedRectangle(toolbar.isSuperscript))
                    Button(action: toggleSubscript) { Image(systemName: "textformat.subscript") }
                        .frame(width: buttonWidth, height: buttonHeight)
                        .background(roundedRectangle(toolbar.isSubscript))
                    Button(action: increaseFontSize) { Image(systemName: "plus.circle") }
                        .padding(edgeInsets)
                    Text(String(format: "%.1f", toolbar.fontSize)).font(.body)
                    Button(action: decreaseFontSize) { Image(systemName: "minus.circle") }
                        .padding(edgeInsets)
                    Button(action: alignText) { Image(systemName: toolbar.textAlignment.imageName)}
                }
                Button(action: insertImage) { Image(systemName: "photo.on.rectangle.angled") }
                    .frame(width: buttonWidth, height: buttonHeight)
                    .background(roundedRectangle())
                Spacer()
                Button(action: {
                    toolbar.textView.resignFirstResponder()
                }) { Image(systemName: "keyboard.chevron.compact.down")}
            }.font(.title2)
            HStack {
                ColorPicker(selection: $toolbar.color, supportsOpacity: true) { Button(" Foreground") { selectColor() } }
                    .fixedSize()
                ColorPicker(selection: $toolbar.background, supportsOpacity: true) { Button("Background") { selectBackground() } }
                    .fixedSize()
                Spacer()
            }.padding(.vertical, 4)
        }
        .background(Color(toolBarsBackground))
    }
    
    var attributedText: NSAttributedString { toolbar.textView.attributedText }
    var selectedRange: NSRange { toolbar.textView.selectedRange }
    
    func toggleStrikethrough() {
        let attributedString = NSMutableAttributedString(attributedString: attributedText)
        if selectedRange.isEmpty {
            toolbar.isStrikethrough.toggle()
            toolbar.textView.typingAttributes[.strikethroughStyle] = toolbar.isStrikethrough ? NSUnderlineStyle.single.rawValue : nil
            toolbar.justChanged = true
            if let didChangeSelection = toolbar.textView.delegate?.textViewDidChangeSelection { didChangeSelection(toolbar.textView) }
            return
        }
        var isAllStrikethrough = true
        attributedString.enumerateAttribute(.strikethroughStyle,
                                            in: selectedRange,
                                            options: []) { (value, range, stopFlag) in
            let strikethrough = value as? NSNumber
            if strikethrough == nil {
                isAllStrikethrough = false
                stopFlag.pointee = true
            }
        }
        if isAllStrikethrough {
            attributedString.removeAttribute(.strikethroughStyle, range: selectedRange)
        } else {
            attributedString.addAttribute(.strikethroughStyle, value: 1, range: selectedRange)
        }
        updateAttributedText(with: attributedString)
    }
    
    func toggleUnderline() {
        let attributedString = NSMutableAttributedString(attributedString: attributedText)
        if selectedRange.isEmpty {
            toolbar.isUnderline.toggle()
            toolbar.textView.typingAttributes[.underlineStyle] = toolbar.isUnderline ? NSUnderlineStyle.single.rawValue : nil
            toolbar.justChanged = true
            if let didChangeSelection = toolbar.textView.delegate?.textViewDidChangeSelection { didChangeSelection(toolbar.textView) }
            return
        }
        var isAllUnderlined = true
        attributedString.enumerateAttribute(.underlineStyle,
                                            in: selectedRange,
                                            options: []) { (value, range, stopFlag) in
            let underline = value as? NSNumber
            if  underline == nil  {
                isAllUnderlined = false
                stopFlag.pointee = true
            }
        }
        if isAllUnderlined {
            // Bug in iOS 15 when all selected and underlined that I can't fix as yet
            attributedString.removeAttribute(.underlineStyle, range: selectedRange)
        } else {
            attributedString.addAttribute(.underlineStyle,
                                          value: NSUnderlineStyle.single.rawValue,
                                          range: selectedRange)
        }
        updateAttributedText(with: attributedString)
    }
    
    func toggleBoldface() {
        toggleSymbolicTrait(.traitBold)
    }
    
    func toggleItalics() {
        toggleSymbolicTrait(.traitItalic)
    }
    
    private func toggleSymbolicTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
        if selectedRange.isEmpty { // toggle typingAttributes
            toolbar.justChanged = true
            let uiFont = toolbar.textView.typingAttributes[.font] as? UIFont
            if let descriptor = uiFont?.fontDescriptor {
                let isBold = descriptor.symbolicTraits.intersection(.traitBold) == .traitBold
                let isTrait = descriptor.symbolicTraits.intersection(trait) == trait
                // Fix bug in largeTitle by setting bold weight directly
                var weight = isBold ? .bold : descriptor.weight
                weight = trait != .traitBold ? weight : (isBold ? .regular : .bold)
                if let fontDescriptor = isTrait ? descriptor.withSymbolicTraits(descriptor.symbolicTraits.subtracting(trait))
                    : descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(trait)) {
                    toolbar.textView.typingAttributes[.font] = UIFont(descriptor: fontDescriptor.withWeight(weight),
                                                                      size: descriptor.pointSize)
                }
                if let didChangeSelection = toolbar.textView.delegate?.textViewDidChangeSelection { didChangeSelection(toolbar.textView) }
            }
            
        } else {
            let attributedString = NSMutableAttributedString(attributedString: attributedText)
            var isAll = true
            attributedString.enumerateAttribute(.font, in: selectedRange,
                                                options: []) { (value, range, stopFlag) in
                let uiFont = value as? UIFont
                if let descriptor = uiFont?.fontDescriptor {
                    isAll = isAll && descriptor.symbolicTraits.intersection(trait) == trait
                    if !isAll { stopFlag.pointee = true }
                }
            }
            attributedString.enumerateAttribute(.font, in: selectedRange,
                                                options: []) {(value, range, stopFlag) in
                let uiFont = value as? UIFont
                if  let descriptor = uiFont?.fontDescriptor {
                    // Fix bug in largeTitle by setting bold weight directly
                    var weight = descriptor.symbolicTraits.intersection(.traitBold) == .traitBold ? .bold : descriptor.weight
                    weight = trait != .traitBold ? weight : (isAll ? .regular : .bold)
                    if let fontDescriptor = isAll ? descriptor.withSymbolicTraits(descriptor.symbolicTraits.subtracting(trait))
                        : descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(trait)) {
                        attributedString.addAttribute(.font, value: UIFont(descriptor: fontDescriptor.withWeight(weight),
                                                                           size: descriptor.pointSize), range: range)
                    }
                }
            }
            updateAttributedText(with: attributedString)
        }
    }
    
    private func toggleSubscript() {
        toolbar.isSubscript.toggle()
        toggleScript(sub: true)
    }
    
    private func toggleSuperscript() {
        toolbar.isSuperscript.toggle()
        toggleScript(sub: false)
    }
    
    private func toggleScript(sub: Bool = false) {
        let selectedRange = toolbar.textView.selectedRange
        let newOffset = sub ? -0.3 : 0.4
        let attributedString = NSMutableAttributedString(attributedString: attributedText)
        
        if selectedRange.isEmpty { // toggle typingAttributes
            var fontSize = toolbar.fontSize
            let isScript = !(toolbar.textView.typingAttributes[.baselineOffset] as? CGFloat ?? 0.0 == 0.0)
            if toolbar.isSubscript && toolbar.isSuperscript {
                // Turn one off
                if sub { toolbar.isSuperscript = false } else { toolbar.isSubscript = false }
                // Check that baseline is offset the right way
                toolbar.textView.typingAttributes[.baselineOffset] = newOffset*toolbar.fontSize
                // font is already right?
                if !isScript { // baseline is zero but still script
                    fontSize *= 0.75
                    print("baseline not as expected, fontSize =",fontSize)
                }
            }
            if !toolbar.isSubscript && !toolbar.isSuperscript {
                // Both set off so adjust baseline and font
                toolbar.textView.typingAttributes[.baselineOffset] = nil
                // use toolbar.fontSize
                print("baseline is set nil with fontSize =",fontSize)
            } else {
                // One is on
                if isScript { print("baseline was expected to be nil")}
                toolbar.textView.typingAttributes[.baselineOffset] = newOffset*toolbar.fontSize
                fontSize *= 0.75
                print("one is on with fontSize =",fontSize)
            }
            var newFont : UIFont
            let descriptor: UIFontDescriptor
            if let font = toolbar.textView.typingAttributes[.font] as? UIFont {
                descriptor = font.fontDescriptor
                newFont = UIFont(descriptor: descriptor, size: fontSize)
                if descriptor.symbolicTraits.intersection(.traitItalic) == .traitItalic, let font = newFont.italic() {
                    newFont = font
                }
            } else { newFont = UIFont.preferredFont(forTextStyle: .body) }
            toolbar.textView.typingAttributes[.font] =  newFont
            toolbar.justChanged = true
            if let didChangeSelection = toolbar.textView.delegate?.textViewDidChangeSelection { didChangeSelection(toolbar.textView) }
            return
        }
        var isAllScript = true
        attributedString.enumerateAttributes(in: selectedRange,
                                             options: []) { (attributes, range, stopFlag) in
            let offset = attributes[.baselineOffset] as? CGFloat ?? 0.0
            if offset == 0.0 { //  normal
                isAllScript = false
            } else { // its super or subscript so set to normal
                // Enlarge font and remove baselineOffset
                var newFont : UIFont
                let descriptor: UIFontDescriptor
                if let font = attributes[.font] as? UIFont {
                    descriptor = font.fontDescriptor
                    newFont = UIFont(descriptor: descriptor, size: descriptor.pointSize/0.75)
                    attributedString.removeAttribute(.baselineOffset, range: range)
                    attributedString.removeAttribute(.font, range: range)
                    if descriptor.symbolicTraits.intersection(.traitItalic) == .traitItalic, let font = newFont.italic() {
                        newFont = font
                    }
                } else { newFont = UIFont.preferredFont(forTextStyle: .body) }
                attributedString.addAttribute(.font, value: newFont, range: range)
            }
        }
        // Now attributedString is free of scripts so if isAllScript we are done
        if !isAllScript {
            // set to script
            attributedString.enumerateAttributes(in: selectedRange,
                                                 options: []) {(attributes, range, stopFlag) in
                var newFont : UIFont
                let descriptor: UIFontDescriptor
                if let font = attributes[.font] as? UIFont {
                    let isBold = font.contains(trait: .traitBold)
                    descriptor = font.fontDescriptor
                    attributedString.addAttribute(.baselineOffset, value: newOffset*descriptor.pointSize,
                                                  range: range)
                    newFont = UIFont(descriptor: descriptor, size: 0.75*descriptor.pointSize)
                    if descriptor.symbolicTraits.intersection(.traitItalic) == .traitItalic, let font = newFont.italic() {
                        newFont = isBold ? font.withWeight(.bold) : font
                    }
                } else { newFont = UIFont.preferredFont(forTextStyle: .body) }
                attributedString.addAttribute(.font, value: newFont, range: range)
            }
        }
        updateAttributedText(with: attributedString)
    }
    
    
    private func alignText() {
        var textAlignment: NSTextAlignment
        switch toolbar.textAlignment {
        case .left: textAlignment = .center
        case .center: textAlignment = .right
        case .right: textAlignment = .left
        case .justified: textAlignment = .justified
        case .natural: textAlignment = .center
        @unknown default: textAlignment = .left
        }
        toolbar.textAlignment = textAlignment
        toolbar.textView.textAlignment = textAlignment
        if let update = toolbar.textView.delegate?.textViewDidChange {
            update(toolbar.textView)
        }
    }
    
    /// Add text attribute to text view
    private func textEffect<T: Equatable>(range: NSRange, key: NSAttributedString.Key, value: T, defaultValue: T) {
        if !range.isEmpty {
            let mutableString = NSMutableAttributedString(attributedString: toolbar.textView.attributedText)
            mutableString.removeAttribute(key, range: range)
            mutableString.addAttributes([key : value], range: range)
            // Update parent
            toolbar.textView.updateAttributedText(with: mutableString)
        } else { print("empty texteffect")
            if let current = toolbar.textView.typingAttributes[key], current as! T == value  {
                toolbar.textView.typingAttributes[key] = defaultValue
            } else {
                toolbar.textView.typingAttributes[key] = value
            }
        }
        toolbar.textView.selectedRange = range // restore selection
    }
    
    private func adjustFontSize(isIncrease: Bool) {
        let textRange = toolbar.textView.selectedRange
        var selectedRangeAttributes: [(NSRange, [NSAttributedString.Key : Any])] {
            var textAttributes: [(NSRange, [NSAttributedString.Key : Any])] = []
            if textRange.isEmpty {
                textAttributes = [(textRange, toolbar.textView.typingAttributes)]
            } else {
                toolbar.textView.attributedText.enumerateAttributes(in: textRange) { attributes, range, stop in
                    textAttributes.append((range,attributes))
                }
            }
            return textAttributes
        }
        var font: UIFont
        let defaultFont = UIFont.preferredFont(forTextStyle: .body)
        let maxFontSize: CGFloat = 80
        let minFontSize: CGFloat = 8
        let rangesAttributes = selectedRangeAttributes
        if textRange.isEmpty {
            font = selectedRangeAttributes[0].1[.font] as? UIFont ?? defaultFont
            let offset = selectedRangeAttributes[0].1[.baselineOffset] as? CGFloat ?? 0.0
            let weight = font.fontDescriptor.symbolicTraits.intersection(.traitBold) == .traitBold ? .bold : font.fontDescriptor.weight
            let size = toolbar.fontSize
            let fontSize = Int(size + CGFloat(isIncrease ? (size < maxFontSize ? 1 : 0) : (size > minFontSize ? -1 : 0)) + 0.5)
            font = UIFont(descriptor: font.fontDescriptor, size: CGFloat(fontSize) * (offset == 0 ? 1.0 : 0.75) ).withWeight(weight)
            toolbar.textView.typingAttributes[.font] = font
            toolbar.fontSize = CGFloat(fontSize)
        } else {
            for (range, attributes) in rangesAttributes {
                font = attributes[.font] as? UIFont ?? defaultFont
                let offset = selectedRangeAttributes[0].1[.baselineOffset] as? CGFloat ?? 0.0
                let weight = font.fontDescriptor.symbolicTraits.intersection(.traitBold) == .traitBold ? .bold : font.fontDescriptor.weight
                let size = font.fontDescriptor.pointSize / (offset == 0 ? 1.0 : 0.75 )
                let fontSize = Int(size + CGFloat(isIncrease ? (size < maxFontSize ? 1 : 0) : (size > minFontSize ? -1 : 0)) + 0.5)
                font = UIFont(descriptor: font.fontDescriptor, size: CGFloat(fontSize) * (offset == 0 ? 1.0 : 0.75) ).withWeight(weight)
                textEffect(range: range, key: .font, value: font, defaultValue: defaultFont)
            }
        }
        toolbar.textView.selectedRange = textRange // restore range
    }
    
    private func increaseFontSize() {
        adjustFontSize(isIncrease: true)
    }
    
    private func decreaseFontSize() {
        adjustFontSize(isIncrease: false)
    }
    
    func insertImage() {
        let delegate = toolbar.textView.delegate as? TextEditorWrapper.Coordinator
        if let delegate { delegate.insertImage() }
    }
    
    // MARK: - Color Selection Button Actions
    private func selectColor() {
        let color = UIColor(toolbar.color)
        textEffect(range: toolbar.textView.selectedRange, key: .foregroundColor, value: color, defaultValue: color)
    }
    
    private func selectBackground() {
        let color = UIColor(toolbar.background)
        textEffect(range: toolbar.textView.selectedRange, key: .backgroundColor, value: color, defaultValue: color)
    }

}

struct KeyBoardAddition_Previews: PreviewProvider {
    @State static var toolbar: KeyBoardToolBar = .init(textView: TextEditorWrapper.MyTextView(), isUnderline: true)
    static var previews: some View {
        KeyBoardAddition(toolbar: .constant(toolbar))
    }
}
