# RichTextEditor
RichTextEditor is yet another SwiftUI attributed string text editor based on UITextView.

Unlike other incarnations of this type this version takes a binding to a Swift value type AttributedString rather than the reference type NSAttributedString. The font attributes of the AttributedString are translated from SwiftUI Font types to UIKit UIFont types using the routines found in FontToUIFont.swift. Which is not always perfect but serves this application well.

A toolbar for iOS/iPadOS is attached to the keyboard using the UITextView's inputAccessoryView.  The KeyboardAccessoryView is configurable via the arrays leadingButtons and trailingButtons of KeyboardCommand types.  While images can be added to the attributedText of the underlying UITextView they are not displayed by a Text view as they are not (yet) supported in SwiftUI AttributedStrings. The frame size of RichTextEditor is set to the height and width of the text in it similarly to the way Text handles this.  The toggle attribute buttons have be rewritten to avoid wiping out font size, italic and bold traits when settings bold or italics and to avoid inconsistency between iOS versions.  The example below gets you started.

	//  RichTextEditorTest
	//
	//  Created by Joseph Levy on 11/15/23.
	//

	import SwiftUI
	import RichTextEditor
	struct ContentView: View {
		@State var text = AttributedString("Hello World!\nThis is the second line and its long.\nThis is a third line.")
	
		var body: some View {
			VStack(alignment: .leading) {
				Text(text)
				Rectangle().frame(height: 5)
					HStack {
						RichTextEditor($text)
						Spacer()
					}
				}
			}
    	}

	#Preview {
		ContentView()
	}

The toolbar still needs to be setup to work in macCatalyst and the macOS Fonts window will not set the backgroundColor of the  attributedText for unknown reasons.  
