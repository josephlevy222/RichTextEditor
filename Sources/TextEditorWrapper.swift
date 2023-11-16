//
//  TextEditorWrapper.swift
//  TextView-Example
//
//  Created by Steven Zhang on 3/12/22.
//  Modified a lot by Joseph Levy on 8/16/23

import SwiftUI

@available(iOS 13.0, *)
public struct RichTextEditor: View {
    @State var dynamicSize = CGSize(width: 100, height: 100)
    @Binding public var attributedText: AttributedString
    @State var undoManager : UndoManager?
    private let placeholder: String
    private let onCommit: (NSAttributedString) -> Void
    
    public init(
        attributedText: Binding<AttributedString>,
        placeholder: String = "Type ...",
        onCommit: @escaping ((NSAttributedString) -> Void) = { _ in}
    ) {
        _attributedText = attributedText
        self.placeholder = placeholder
        self.onCommit = onCommit
    }
    
    public var body: some View {
        TextEditorWrapper(attributedText: $attributedText,undoManager: $undoManager, size: $dynamicSize, placeholder: placeholder, onCommit: onCommit)
            .frame(minHeight: dynamicSize.height ,
                   maxHeight: dynamicSize.height)
    }
}

extension NSTextAlignment {
    var imageName: String {
        switch self {
        case .left: return "text.alignleft"
        case .center: return "text.aligncenter"
        case .right: return "text.alignright"
        case .justified: return "text.natural"
        case .natural: return "text.alignleft"
        @unknown default: return "text.aligncenter"
        }
    }
    static let available: [NSTextAlignment] = [.left, .right, .center]
}

@available(iOS 13.0, *)
struct TextEditorWrapper: UIViewControllerRepresentable {
    @Binding var attributedText: AttributedString
    @Binding var undoManager: UndoManager?
    @Binding private var size: CGSize
    
    internal var controller: UIViewController
    private var accessoryViewController: UIHostingController<KeyBoardAddition>?
    
    private let placeholder: String
    private let lineSpacing: CGFloat = 3
    private let hintColor = UIColor.placeholderText
    private let defaultFontSize = UIFont.systemFontSize
    private let defaultFontName = UIFont.systemFont(ofSize: 17).fontDescriptor.fontAttributes[.name] as? String ?? "SFUI"
    private let onCommit: ((NSAttributedString) -> Void)
    
    private var defaultFont: UIFont {
        return UIFont(name: defaultFontName, size: defaultFontSize) ?? .systemFont(ofSize: defaultFontSize)
    }
    
    @State var toolbar : KeyBoardToolBar
    var textView: MyTextView
    // TODO: line width, line style
    init(
        attributedText: Binding<AttributedString>,
        undoManager: Binding<UndoManager?>,
        size: Binding<CGSize>,
        placeholder: String,
        onCommit: @escaping ((NSAttributedString) -> Void)
    ) {
        _attributedText = attributedText
        _undoManager = undoManager
        self._size = size
        self.controller = UIViewController()
        let newTextView = MyTextView()
        self.textView = newTextView
        self.placeholder = placeholder
        self.onCommit = onCommit
        self._toolbar = State(initialValue: KeyBoardToolBar(textView: newTextView, isBold: false, isItalic: false, isUnderline: false, isStrikethrough: false, isSuperscript: false, isSubscript: false, fontSize: 17, color: Color(uiColor: .label), background: Color(uiColor: .systemBackground)))

    }
    
    func makeUIViewController(context: Context) -> some UIViewController {
        toolbar.textView.delegate = context.coordinator
        setUpTextView()
        let accessoryViewController = UIHostingController(rootView: KeyBoardAddition(toolbar: $toolbar))
        DispatchQueue.main.async {
            undoManager = self.textView.undoManager
            context.coordinator.textViewDidChange(toolbar.textView)
        }
        toolbar.textView.inputAccessoryView = {
            let accessoryView = accessoryViewController.view
            if let accessoryView {
                let frameSize = CGRect(x: 0, y: 0, width: 100, height: 80)
                accessoryView.frame = frameSize }
            return accessoryView
        }()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        let selected = context.coordinator.parent.toolbar.textView.selectedRange
        let newText = attributedText.convertToUIAttributes()
        context.coordinator.parent.toolbar.textView.attributedText =  newText
        context.coordinator.parent.toolbar.textView.selectedRange = selected
        // apparently the context is assigned to the "state" after this,
        // so without changing the context nothing happens
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func setUpTextView() {
        let richText = attributedText.convertToUIAttributes()
        if richText.string == "" {
            toolbar.textView.attributedText = NSAttributedString(string: placeholder, attributes: [.foregroundColor: hintColor])
        } else {
            toolbar.textView.attributedText = richText
        }
        toolbar.textView.typingAttributes = [.font : defaultFont]
        toolbar.textView.isEditable = true
        toolbar.textView.isSelectable = true
        toolbar.textView.isScrollEnabled = false
        toolbar.textView.isUserInteractionEnabled = true
        toolbar.textView.textAlignment = .left
        
        toolbar.textView.textContainerInset = UIEdgeInsets.zero
        toolbar.textView.textContainer.lineFragmentPadding = 0
        //toolbar.textView.layoutManager.allowsNonContiguousLayout = false
        toolbar.textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        toolbar.textView.backgroundColor = .clear
        toolbar.textView.textColor = .label
        controller.view.addSubview(toolbar.textView)
        toolbar.textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toolbar.textView.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
            toolbar.textView.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor),
            toolbar.textView.widthAnchor.constraint(equalTo: controller.view.widthAnchor),
        ])
    }
    
    private func scaleImage(image: UIImage, maxWidth: CGFloat, maxHeight: CGFloat) -> UIImage {
        let ratio = image.size.width / image.size.height
        let imageW: CGFloat = (ratio >= 1) ? maxWidth : image.size.width*(maxHeight/image.size.height)
        let imageH: CGFloat = (ratio <= 1) ? maxHeight : image.size.height*(maxWidth/image.size.width)
        UIGraphicsBeginImageContext(CGSize(width: imageW, height: imageH))
        image.draw(in: CGRect(x: 0, y: 0, width: imageW, height: imageH))
        let scaledimage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledimage!
    }
    
    class Coordinator: NSObject, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIColorPickerViewControllerDelegate {
        var parent: TextEditorWrapper
        var fontName: String
        
        init(_ parent: TextEditorWrapper) {
            self.parent = parent
            self.fontName = parent.defaultFontName
        }
        
        // MARK: - Image Picker
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let img = info[UIImagePickerController.InfoKey.editedImage] as? UIImage, var image = img.roundedImageWithBorder(color: .secondarySystemBackground) {
                textViewDidBeginEditing(parent.toolbar.textView)
                let newString = NSMutableAttributedString(attributedString: parent.toolbar.textView.attributedText)
                image = scaleImage(image: image, maxWidth: 180, maxHeight: 180)
                
                let textAttachment = NSTextAttachment(image: image)
                let attachmentString = NSAttributedString(attachment: textAttachment)
                newString.append(attachmentString)
                parent.toolbar.textView.attributedText = newString
                textViewDidChange(parent.toolbar.textView)
            }
            picker.dismiss(animated: true, completion: nil)
        }
        
        func scaleImage(image: UIImage, maxWidth: CGFloat, maxHeight: CGFloat) -> UIImage {
            let ratio = image.size.width / image.size.height
            let imageW: CGFloat = (ratio >= 1) ? maxWidth : image.size.width*(maxHeight/image.size.height)
            let imageH: CGFloat = (ratio <= 1) ? maxHeight : image.size.height*(maxWidth/image.size.width)
            UIGraphicsBeginImageContext(CGSize(width: imageW, height: imageH))
            image.draw(in: CGRect(x: 0, y: 0, width: imageW, height: imageH))
            let scaledimage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return scaledimage!
        }
        
        // MARK: - Text Editor Delegate
        
        func adjustFontSize(isIncrease: Bool) {
            var font: UIFont
            let defaultFont = UIFont.preferredFont(forTextStyle: .body)
            let maxFontSize: CGFloat = 80
            let minFontSize: CGFloat = 8
            let rangesAttributes = selectedRangeAttributes
            for (range, attributes) in rangesAttributes {
                font = attributes[.font] as? UIFont ?? defaultFont
                let weight = font.fontDescriptor.symbolicTraits.intersection(.traitBold) == .traitBold ? .bold : font.fontDescriptor.weight
                let size = font.fontDescriptor.pointSize
                let fontSize = size + CGFloat(isIncrease ? (size < maxFontSize ? 1 : 0) : (size > minFontSize ? -1 : 0))
                font = UIFont(descriptor: font.fontDescriptor, size: fontSize).withWeight(weight)
                textEffect(range: range, key: .font, value: font, defaultValue: defaultFont)
            }
        }
        
        /// Not used yet?
        func textFont(name: String) {
            let attributes = parent.toolbar.textView.selectedRange.isEmpty ? parent.toolbar.textView.typingAttributes : selectedAttributes
            let fontSize = getFontSize(attributes: attributes)
            
            fontName = name
            let defaultFont = UIFont.preferredFont(forTextStyle: .body)
            let newFont = UIFont(name: fontName, size: fontSize) ?? defaultFont
            textEffect(range: parent.toolbar.textView.selectedRange, key: .font, value: newFont, defaultValue: defaultFont)
        }
        
        func textColor(color: UIColor) {
            textEffect(range: parent.toolbar.textView.selectedRange, key: .foregroundColor, value: color, defaultValue: color)
        }
        
        func textBackground(color: UIColor) {
            textEffect(range: parent.toolbar.textView.selectedRange, key: .backgroundColor, value: color, defaultValue: color)
        }
 
        func insertImage() {
            let sourceType = UIImagePickerController.SourceType.photoLibrary
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.sourceType = sourceType
            parent.controller.present(imagePicker, animated: true, completion: nil)
        }
        
        func insertLine(name: String) {
            if let line = UIImage(named: name) {
                let newString = NSMutableAttributedString(attributedString: parent.toolbar.textView.attributedText)
                let image = scaleImage(image: line, maxWidth: 280, maxHeight: 20)
                let attachment = NSTextAttachment(image: image)
                let attachedString = NSAttributedString(attachment: attachment)
                newString.append(attachedString)
                parent.toolbar.textView.attributedText = newString
            }
        }
        
        func hideKeyboard() {
            parent.toolbar.textView.resignFirstResponder()
        }
        
        /// Add text attribute to text view
        private func textEffect<T: Equatable>(range: NSRange, key: NSAttributedString.Key, value: T, defaultValue: T) {
            if !range.isEmpty {
                let mutableString = NSMutableAttributedString(attributedString: parent.toolbar.textView.attributedText)
                mutableString.removeAttribute(key, range: range)
                mutableString.addAttributes([key : value], range: range)
                parent.toolbar.textView.updateAttributedText(with: mutableString)
            } else {
                if let current = parent.toolbar.textView.typingAttributes[key], current as! T == value  {
                    parent.toolbar.textView.typingAttributes[key] = defaultValue
                } else {
                    parent.toolbar.textView.typingAttributes[key] = value
                }
            }
            parent.toolbar.textView.selectedRange = range // restore selection
        }
        
        private func getFontSize(attributes: [NSAttributedString.Key : Any]) -> CGFloat {
            let font = attributes[.font] as? UIFont ?? UIFont.preferredFont(forTextStyle: .body)
            return font.pointSize
        }
        
        var selectedAttributes: [NSAttributedString.Key : Any] {
            let textRange = parent.toolbar.textView.selectedRange
            var textAttributes = parent.toolbar.textView.typingAttributes
            if !textRange.isEmpty {
                //textAttributes = [:] // Uncomment to avoid system putting values in typingAttributes
                parent.toolbar.textView.attributedText.enumerateAttributes(in: textRange) { attributes, range, stop in
                    for item in attributes {
                        textAttributes[item.key] = item.value
                    }
                }
            }
            return textAttributes
        }
        
        var selectedRangeAttributes: [(NSRange, [NSAttributedString.Key : Any])] {
            let textRange = parent.toolbar.textView.selectedRange
            if textRange.isEmpty { return [(textRange, parent.toolbar.textView.typingAttributes)]}
            var textAttributes: [(NSRange, [NSAttributedString.Key : Any])] = []
            parent.toolbar.textView.attributedText.enumerateAttributes(in: textRange) { attributes, range, stop in
                textAttributes.append((range,attributes))
            }
            return textAttributes
        }
        
        // MARK: - Text View Delegate
        func textViewDidChangeSelection(_ textView: UITextView) {
            let attributes = selectedAttributes
            
            let fontTraits: (isBold: Bool,isItalic: Bool,fontSize: CGFloat, offset: CGFloat) = {
                let offset = attributes[.baselineOffset] as? CGFloat ?? 0.0
                let pointSize: CGFloat
                if parent.toolbar.justChanged {
                    pointSize = parent.toolbar.fontSize
                }
                else {
                    if let font=attributes[.font] as? UIFont {
                        pointSize = font.pointSize / (offset == 0.0 ? 1.0 : 0.75)
                        // pointSize is the fontSize that the toolbar ought to use unless justChanged
                        return (font.contains(trait: .traitBold),font.contains(trait: .traitItalic), pointSize, offset)
                    }
                    print("Non UIFont in fontTraits")
                    pointSize = UIFont.preferredFont(forTextStyle: .body).pointSize
                }
                return ( false, false, pointSize, offset)
            }()
            
            var isUnderline: Bool {
                parent.toolbar.justChanged ? parent.toolbar.isUnderline : {
                    if let style = attributes[.underlineStyle] as? Int {
                        return style == NSUnderlineStyle.single.rawValue // or true
                    } else {
                        return false
                    }
                }()
            }
            
            var isStrikethrough: Bool {
                parent.toolbar.justChanged ? parent.toolbar.isStrikethrough : {
                    if let style = attributes[.strikethroughStyle] as? Int {
                        return style == NSUnderlineStyle.single.rawValue
                    } else {
                        return false
                    }
                }()
            }
            
            var isScript: (sub: Bool,super: Bool) {
                return parent.toolbar.justChanged
                    ? (parent.toolbar.isSubscript, parent.toolbar.isSuperscript)
                    : (fontTraits.offset < 0.0, fontTraits.offset > 0.0)
            }
            
            var color: UIColor { selectedAttributes[.foregroundColor] as? UIColor ?? UIColor.label }
            var background: UIColor  { selectedAttributes[.backgroundColor] as? UIColor ?? UIColor.systemBackground }
            
            if let color = parent.toolbar.textView.typingAttributes[.backgroundColor] as? UIColor, color.luminance < 0.55 {
                textView.tintColor =  .cyan
            } else {
                textView.tintColor = .tintColor
            }
            DispatchQueue.main.async { [self] in
                parent.toolbar.fontSize = fontTraits.fontSize
                parent.toolbar.isBold = fontTraits.isBold
                parent.toolbar.isItalic = fontTraits.isItalic
                parent.toolbar.isUnderline = isUnderline
                parent.toolbar.isStrikethrough = isStrikethrough
                let script = isScript
                parent.toolbar.isSuperscript = script.1 //isSuperscript
                parent.toolbar.isSubscript = script.0 //isSubscript
                parent.toolbar.color = Color(uiColor: color)
                parent.toolbar.background = Color(uiColor: background)
                parent.toolbar.justChanged = false
            }
        }
        
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.attributedText.string == parent.placeholder {
                textView.attributedText = NSAttributedString(string: "")
                textView.typingAttributes[.foregroundColor] = UIColor.label
            }
            textView.undoManager?.registerUndo(withTarget: self, handler: { targetSelf in
                print("Doing undo")
            })
            
            let selectedRange = textView.selectedRange
            textView.selectedRange = NSRange()
            textView.selectedRange = selectedRange
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.attributedText.string == "" || textView.attributedText.string == parent.placeholder {
                textView.attributedText = NSAttributedString(string: parent.placeholder)
            } else {
                parent.onCommit(textView.attributedText)
            }
            UITextView.appearance().tintColor = .tintColor
        }
        
        func textViewDidChange(_ textView: UITextView) {
            
            if textView.attributedText.string != parent.placeholder {
                self.parent.attributedText = textView.attributedText.uiFontAttributedString
            }
            let size = CGSize(width: parent.controller.view.frame.width, height: .infinity)
            let estimatedSize = textView.sizeThatFits(size)
            if parent.size != estimatedSize {
                DispatchQueue.main.async { self.parent.size = estimatedSize }
            }
            textView.scrollRangeToVisible(textView.selectedRange)
        }
    }
    
    class MyTextView: UITextView, ObservableObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
   
        // This works in iOS 16 but never called in 15 I believe
        open override func buildMenu(with builder: UIMenuBuilder) {
            builder.remove(menu: .lookup) // Remove Lookup, Translate, Search Web
            //builder.remove(menu: .standardEdit) // Keep Cut, Copy, Paste
            //builder.remove(menu: .replace) // Keep Replace
#if !targetEnvironment(macCatalyst)
            builder.remove(menu: .share) // Remove Share
            builder.remove(menu: .textStyle) // Remove Format
#endif
            super.buildMenu(with: builder)
        }
        
        // This is needed for iOS 15
        open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
            if #unavailable(iOS 16.0) {
                //let menuController = UIMenuController.shared

                // Get rid of menu item not wanted
                if action.description.contains("_share") // Share
                    || action.description.contains("_translate") // Translate
                    || action.description.contains("_define") { // Blocks Lookup
                    return false
                }
            }
            return super.canPerformAction(action, withSender: sender)
        }
        /// Make this work with undo/redo
        public func updateAttributedText(with attributedString: NSAttributedString) {
            attributedText = attributedString
            if let update = delegate?.textViewDidChange {
                update(self) }
        }
    }
}
