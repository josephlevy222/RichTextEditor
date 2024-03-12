//
//  Extensions.swift
//  TextView-Example
//
//  Created by Steven Zhang on 3/12/22.
//

import SwiftUI

@available(iOS 13.0, *)
public extension Color {
    init(hex: String, alpha: Double = 1) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = (rgbValue & 0xff)
        
        self.init(red: Double(r)/0xff, green: Double(g)/0xff, blue: Double(b)/0xff, opacity: alpha)
    }
}

public extension UIColor {
    convenience init(hex: String, alpha: Double = 1) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = (rgbValue & 0xff)
        
        self.init(red: Double(r)/0xff, green: Double(g)/0xff, blue: Double(b)/0xff, alpha: alpha)
    }
}

class ColorLibrary {
    static private let textColorHeses: [String] = ["000000", "DD4E48", "ED734A", "F1AA3E", "479D60", "5AC2C5", "50AAF8", "2355F6", "9123F4", "EA5CAE"]
    static let textColors: [UIColor] = textColorHeses.map({ UIColor(hex: $0) })
}

extension UIImage {
    func roundedImageWithBorder(color: UIColor) -> UIImage? {
        let length = min(size.width, size.height)
        let borderWidth = length * 0.04
        let cornerRadius = length * 0.01
        
        let rect = CGSize(width: size.width+borderWidth*1.5, height:size.height+borderWidth*1.8)
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: rect))
        imageView.backgroundColor = color
        imageView.contentMode = .center
        imageView.image = self
        imageView.layer.cornerRadius = cornerRadius
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = borderWidth
        imageView.layer.borderColor = color.cgColor
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}

extension NSRange {
    var isEmpty: Bool {
        self.length == 0
    }
}

extension UIColor {
    
    // get a complementary color to this color
    // https://gist.github.com/klein-artur/025a0fa4f167a648d9ea
    var complementary: UIColor {
        
        let ciColor = CIColor(color: self)
        
        // get the current values and make the difference from white:
        let compRed: CGFloat = 1.0 - ciColor.red
        let compGreen: CGFloat = 1.0 - ciColor.green
        let compBlue: CGFloat = 1.0 - ciColor.blue
        
        return UIColor(red: compRed, green: compGreen, blue: compBlue, alpha: ciColor.alpha)
    }
    
    // perceptive luminance
    // https://stackoverflow.com/questions/1855884/determine-font-color-based-on-background-color
    var contrast: UIColor {
        
        // Counting the perceptive luminance - human eye favors green color...
        let luminance = self.luminance
        // bright colors - black font
        // dark colors - white font
        let col: CGFloat = luminance < 0.55 ? 0 : 1
        
        return UIColor( red: col, green: col, blue: col, alpha: ciColor.alpha)
    }
    
    func contrast(threshold: CGFloat = 0.65, bright: UIColor = .white, dark: UIColor = .black) -> UIColor {
        // Counting the perceptive luminance - human eye favors green color...
        let luminance = self.luminance
        //let rounded = CGFloat( round(1000 * luminance) / 1000 )
        return luminance < threshold ? dark : bright
    }
    
    var luminance: CGFloat {
        let ciColor = CIColor(color: self)
        
        let compRed = 0.299 * ciColor.red
        let compGreen = 0.587 * ciColor.green
        let compBlue = 0.114 * ciColor.blue
        
        // Counting the perceptive luminance - human eye favors green color...
        let luminance = (compRed + compGreen + compBlue)
        return luminance
    }
}

// Hack to use UIViewRepresentable instead of UIViewControllerRepresentable for TextEditorWrapper
extension UIView {
	var parentViewController: UIViewController? {
		sequence(first: self) { $0.next }
			.compactMap{ $0 as? UIViewController }
			.first
	}
}
