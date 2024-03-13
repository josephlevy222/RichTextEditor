//
//  KeyBoardAddition.swift
//  RichTextField
//
//  Created by Joseph Levy on 9/10/23.
//

import SwiftUI

public struct KeyboardToolbar  {
    
    var textView: TextEditorWrapper.RichTextView
    var isBold: Bool = false
    var isItalic: Bool = false
    var isUnderline: Bool = false
    var isStrikethrough: Bool = false
    var isSuperscript: Bool = false
    var isSubscript: Bool = false
    var fontSize: CGFloat = 17
	var textAlignment: NSTextAlignment = .center
    var color : Color = Color(uiColor: .label)
    var background: Color = Color(uiColor: .clear)
    
    var justChanged: Bool = false
}

enum KeyboardCommand : Identifiable {
	case bold,italic,underline,strikethrough,superscript,subscripts,modifyFontSize,alignText,insertImage,selectColor,
		 selectBackground,dismissKeyboard
	var id : String { String(describing: self)}
}

public struct KeyboardAccessoryView: View {
	@Binding var toolbar: KeyboardToolbar
	let inputClick = InputClickPlayer()
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
	
	func keyboardButtonView(_ button: KeyboardCommand) -> some View {
		func symbol(_ name: String) -> Image { .init(systemName: name) }
		func space(_ width: CGFloat) -> some View { Color.clear.frame(width: width)}
		return HStack(spacing: 1) {
			switch button {
			case .bold:
				Button(action: toggleBoldface) { symbol("bold") }
					.frame(width: buttonWidth, height: buttonHeight)
					.background(roundedRectangle(toolbar.isBold))
			case .italic:
				Button(action: toggleItalics) { symbol("italic") }
					.frame(width: buttonWidth, height: buttonHeight)
					.background(roundedRectangle(toolbar.isItalic))
			case .underline:
				Button(action: toggleUnderline) { symbol("underline") }
					.frame(width: buttonWidth, height: buttonHeight)
					.background(roundedRectangle(toolbar.isUnderline))
			case .strikethrough:
				Button(action: toggleStrikethrough) { symbol("strikethrough") }
					.frame(width: buttonWidth, height: buttonHeight)
					.background(roundedRectangle(toolbar.isStrikethrough))
			case .superscript:
				Button(action: toggleSuperscript) { symbol("textformat.superscript") }
					.frame(width: buttonWidth, height: buttonHeight)
					.background(roundedRectangle(toolbar.isSuperscript))
			case .subscripts:
				Button(action: toggleSubscript) { symbol("textformat.subscript") }
					.frame(width: buttonWidth, height: buttonHeight)
					.background(roundedRectangle(toolbar.isSubscript))
			case .modifyFontSize:
				Divider()
				space(4)
				HStack(spacing: 4) {
					Button(action: increaseFontSize) { symbol("plus.circle") }
					Text(String(format: "%.1f", toolbar.fontSize)).font(.body)
					Button(action: decreaseFontSize) { symbol("minus.circle") }
				}
				space(4)
				Divider()
			case .alignText:
				Button(action: alignText) { symbol(toolbar.textAlignment.imageName)}
			case .insertImage:
				Button(action: insertImage) { symbol("photo.on.rectangle.angled") }
					.frame(width: buttonWidth, height: buttonHeight)
					.background(roundedRectangle())
			case .selectColor:
				space(5)
				ColorPicker(selection: $toolbar.color, supportsOpacity: true) {
					Button(action: selectColor) { symbol("character") } }
				.fixedSize()
				space(5)
			case .selectBackground:
				space(5)
				ColorPicker(selection: $toolbar.background, supportsOpacity: true) {
					Button(action: selectBackground) { symbol("a.square") } }
				.fixedSize()
				space(5)
			case .dismissKeyboard:
				Button(action: {
					toolbar.textView.resignFirstResponder()
				}) { symbol("keyboard.chevron.compact.down")}
					.padding(edgeInsets)
			}
			
		}
	}
		
	func keyboardButtons(_ buttons: [KeyboardCommand]) -> some View {
		HStack(spacing: 1) {
			ForEach(buttons) { keyboardButtonView($0) }
		}
	}
	
	let leadingButtons: [KeyboardCommand] = [.bold,.italic,.underline,.strikethrough,.superscript,.subscripts,.modifyFontSize,.selectColor,.selectBackground,.alignText]
	let trailingButtons: [KeyboardCommand] = [.dismissKeyboard]
    
	public var body: some View {
		HStack(spacing: 1) {
			keyboardButtons(leadingButtons)
			Spacer()
			keyboardButtons(trailingButtons)
		}
        .background(Color(toolBarsBackground))
    }
    
    var attributedText: NSAttributedString { toolbar.textView.attributedText }
    var selectedRange: NSRange { toolbar.textView.selectedRange }
    
    func toggleStrikethrough() {
		inputClick.play()
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
		inputClick.play()
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
    
    private func toggleSymbolicTrait(_ trait: UIFontDescriptor.SymbolicTraits)  {
		inputClick.play()
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
                    toolbar.textView.typingAttributes[.font] = UIFont(descriptor: fontDescriptor.withWeight(weight), size: descriptor.pointSize)
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
					let isTrait = (descriptor.symbolicTraits.intersection(trait) == trait)
                    isAll = isAll && isTrait
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
		inputClick.play()
        let selectedRange = toolbar.textView.selectedRange
        let newOffset = sub ? -0.3 : 0.4
        let attributedString = NSMutableAttributedString(attributedString: attributedText)
        
        if selectedRange.isEmpty { // toggle typingAttributes
            var fontSize = toolbar.fontSize
            if toolbar.isSubscript && toolbar.isSuperscript { // Both on
                // Turn one off
                if sub { toolbar.isSuperscript = false } else { toolbar.isSubscript = false }
                // Check that baseline is offset the right way
                toolbar.textView.typingAttributes[.baselineOffset] = newOffset*toolbar.fontSize
                // font is already right
            }
            if !toolbar.isSubscript && !toolbar.isSuperscript {
                // Both set off so adjust baseline and font
                toolbar.textView.typingAttributes[.baselineOffset] = nil
                // use toolbar.fontSize
                //print("baseline is set nil with fontSize =",fontSize)
            } else {  // One is on
                toolbar.textView.typingAttributes[.baselineOffset] = newOffset*toolbar.fontSize
                fontSize *= 0.75
                //print("one is on with fontSize =",fontSize)
            }
            var newFont : UIFont
            let descriptor: UIFontDescriptor
            if let font = toolbar.textView.typingAttributes[.font] as? UIFont {
                descriptor = font.fontDescriptor
				let traits = descriptor.symbolicTraits.union(.traitTightLeading)
				
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
					descriptor = font.fontDescriptor.withSymbolicTraits(font.fontDescriptor.symbolicTraits.union(.traitTightLeading)) ?? font.fontDescriptor
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
		inputClick.play()
		toolbar.textAlignment = switch toolbar.textAlignment {
			case .left: .center
			case .center: .right
			case .right:  .left
			case .justified: .justified
			case .natural: .center
			@unknown default: .left
		}
        if let update = toolbar.textView.delegate?.textViewDidChange {
            update(toolbar.textView)
        }
    }
    
    /// Add text attribute to text view
    private func textEffect<T: Equatable>(range: NSRange, key: NSAttributedString.Key, value: T, defaultValue: T) {
		inputClick.play()
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
		inputClick.play()
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
		inputClick.play()
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
    @State static var toolbar: KeyboardToolbar = .init(textView: TextEditorWrapper.RichTextView(), isUnderline: true)
    static var previews: some View {
        KeyboardAccessoryView(toolbar: .constant(toolbar))
    }
}

import AVFoundation
public class InputClickPlayer {
	private var soundID: SystemSoundID
	init() {
		soundID = 0
		if let filePath = Bundle.module.path(forResource: "sound56", ofType: "wav") {
			let fileURL = URL(fileURLWithPath: filePath)
			AudioServicesCreateSystemSoundID(fileURL as CFURL, &soundID)
		} else { debugPrint("Error getting button click file sound56.wav") }
	}
	
	public func play() { AudioServicesPlaySystemSound(soundID) }
}



