//
//  ClassExtensions.swift
//  ShazamForImages
//
//  Created by Allen X on 6/3/17.
//  Copyright © 2017 allenx. All rights reserved.
//

import Foundation
import UIKit
import CoreVideo
import AVFoundation

extension UILabel {
    convenience init(text: String, color: UIColor) {
        self.init()
        self.text = text
        textColor = color
        self.sizeToFit()
    }
    
    convenience init(text: String?) {
        self.init()
        self.text = text
        self.sizeToFit()
    }
    
    convenience init(text: String, boldFontSize: CGFloat) {
        self.init()
        self.text = text
        self.font = UIFont.boldSystemFont(ofSize: boldFontSize)
        self.sizeToFit()
    }
    
    convenience init(text: String, fontSize: CGFloat) {
        self.init()
        self.text = text
        self.font = UIFont.systemFont(ofSize: fontSize)
        self.sizeToFit()
    }
    
}



extension UIView {
    convenience init(color: UIColor) {
        self.init()
        backgroundColor = color
    }
    
    func snapshot() -> UIImage? {
        UIGraphicsBeginImageContext(self.bounds.size)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension UIImage {
    
    static func resizedImage(image: UIImage, scaledToSize newSize: CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        image.draw(in: CGRect(x: 0.0, y: 0, width: newSize.width, height: newSize.height))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    
    static func resizedImageKeepingRatio(image: UIImage, scaledToWidth newWidth: CGFloat) -> UIImage {
        let scaleRatio = newWidth / image.size.width
        let newHeight = image.size.height * scaleRatio
        let foo = UIImage.resizedImage(image: image, scaledToSize: CGSize(width: newWidth, height: newHeight))
        return foo
    }
    
    static func resizedImageKeepingRatio(image: UIImage, scaledToHeight newHeight: CGFloat) -> UIImage {
        let scaleRatio = newHeight / image.size.height
        let newWidth = image.size.width * scaleRatio
        let foo = UIImage.resizedImage(image: image, scaledToSize: CGSize(width: newWidth, height: newHeight))
        return foo
    }
    
    func rgb(atPos pos: CGPoint) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        
        let pixelData = self.cgImage!.dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let pixelInfo: Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4
        
        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        
        return (r, g, b, a)
    }
    
    
    func smartAvgRGB() -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        //[TODO]: Add smart rgb Filter
        
        //Naïve Algorithm. Squareroot: Weight for a specific RGB value is value^(-1/3)
        let thumbnail = UIImage.resizedImage(image: self, scaledToSize: CGSize(width: 100, height: 100))
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0
        for i in 0..<100 {
            for j in 0..<100 {
                let point = CGPoint(x: i, y: j)
                let rgbOfThisPoint = thumbnail.rgb(atPos: point)
                
                r += (pow(rgbOfThisPoint.red, 1/3))/10000
                g += (pow(rgbOfThisPoint.green, 1/3))/10000
                b += (pow(rgbOfThisPoint.blue, 1/3))/10000
                a += rgbOfThisPoint.alpha/10000
            }
        }
        
        //print(r*255, g*255, b*255, a)
        return (r, g, b, a)
    }
    
    
    func with(color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        color.setFill()
        
        let context = UIGraphicsGetCurrentContext()
        context!.translateBy(x: 0, y: self.size.height)
        context!.scaleBy(x: 1.0, y: -1.0);
        context!.setBlendMode(.normal)
        
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        
        context!.clip(to: rect, mask: self.cgImage!)
        context!.fill(rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()! as UIImage
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
}




extension UIImageView {
    convenience init?(imageName: String, desiredSize: CGSize) {
        guard var foo = UIImage(named: imageName) else {
            return nil
        }
        foo = UIImage.resizedImage(image: foo, scaledToSize: desiredSize)
        self.init()
        image = foo
    }
}




extension UIButton {
    convenience init(title: String) {
        self.init()
        setTitle(title, for: .normal)
        titleLabel?.sizeToFit()
    }
    
    
    convenience init?(backgroundImageName: String, desiredSize: CGSize) {
        guard var foo = UIImage(named: backgroundImageName) else {
            return nil
        }
        foo = UIImage.resizedImage(image: foo, scaledToSize: desiredSize)
        self.init()
        setBackgroundImage(foo, for: .normal)
    }
}

extension UIViewController {
    
    func topViewController() -> UIViewController? {
        if let appRootVC = UIApplication.shared.keyWindow?.rootViewController {
            var topVC: UIViewController? = appRootVC
            while (topVC?.presentedViewController != nil) {
                topVC = topVC?.presentedViewController
            }
            return topVC
        }
        return nil
    }
    
}

//extension String {
//    func sha1() -> String {
//        let data = self.data(using: String.Encoding.utf8)!
//        var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
//        data.withUnsafeBytes {
//            _ = CC_SHA1($0, CC_LONG(data.count), &digest)
//        }
//        let hexBytes = digest.map { String(format: "%02hhx", $0) }
//        return hexBytes.joined()
//    }
//}


extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
        
        return boundingBox.height
    }
}


// TODO: from hex to displayP3 and hsb
extension UIColor {
    
    //    convenience init?(Hex6: String) {
    //
    //        guard Hex.characters.count == 6 else {
    //            print("Hex value for a color needs to be a 6-character String. nil Color initialized")
    //            return nil
    //        }
    //    }
    
    /**
     The six-digit hexadecimal representation of color of the form #RRGGBB.
     
     - parameter hex6: Six-digit hexadecimal value.
     */
    public convenience init(hex6: UInt32, alpha: CGFloat = 1) {
        // TODO: below
        // Store Hex converted UIColours (R, G, B, A) to a persistent file (.plist)
        // And when initializing the app, read from the plist into the memory as a static struct (Metadata.Color)
        let divisor = CGFloat(255)
        let r = CGFloat((hex6 & 0xFF0000) >> 16) / divisor
        let g = CGFloat((hex6 & 0x00FF00) >>  8) / divisor
        let b = CGFloat( hex6 & 0x0000FF       ) / divisor
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}


extension UnicodeScalar {
    
    var isEmoji: Bool {
        
        switch value {
        case 0x3030, 0x00AE, 0x00A9, // Special Characters
        0x1D000 ... 0x1F77F, // Emoticons
        0x2100 ... 0x27BF, // Misc symbols and Dingbats
        0xFE00 ... 0xFE0F, // Variation Selectors
        0x1F900 ... 0x1F9FF: // Supplemental Symbols and Pictographs
            return true
            
        default: return false
        }
    }
    
    var isZeroWidthJoiner: Bool {
        
        return value == 8205
    }
}

extension String {
    
    var glyphCount: Int {
        
        let richText = NSAttributedString(string: self)
        let line = CTLineCreateWithAttributedString(richText)
        return CTLineGetGlyphCount(line)
    }
    
    var isSingleEmoji: Bool {
        
        return glyphCount == 1 && containsEmoji
    }
    
    var containsEmoji: Bool {
        
        return !unicodeScalars.filter { $0.isEmoji }.isEmpty
    }
    
    var containsOnlyEmoji: Bool {
        
        return unicodeScalars.first(where: { !$0.isEmoji && !$0.isZeroWidthJoiner }) == nil
    }
    
    // The next tricks are mostly to demonstrate how tricky it can be to determine emoji's
    // If anyone has suggestions how to improve this, please let me know
    var emojiString: String {
        
        return emojiScalars.map { String($0) }.reduce("", +)
    }
    
    var emojis: [String] {
        
        var scalars: [[UnicodeScalar]] = []
        var currentScalarSet: [UnicodeScalar] = []
        var previousScalar: UnicodeScalar?
        
        for scalar in emojiScalars {
            
            if let prev = previousScalar, !prev.isZeroWidthJoiner && !scalar.isZeroWidthJoiner {
                
                scalars.append(currentScalarSet)
                currentScalarSet = []
            }
            currentScalarSet.append(scalar)
            
            previousScalar = scalar
        }
        
        scalars.append(currentScalarSet)
        
        return scalars.map { $0.map{ String($0) } .reduce("", +) }
    }
    
    fileprivate var emojiScalars: [UnicodeScalar] {
        
        var chars: [UnicodeScalar] = []
        var previous: UnicodeScalar?
        for cur in unicodeScalars {
            
            if let previous = previous, previous.isZeroWidthJoiner && cur.isEmoji {
                chars.append(previous)
                chars.append(cur)
                
            } else if cur.isEmoji {
                chars.append(cur)
            }
            
            previous = cur
        }
        
        return chars
    }
    
    var containsChineseCharacters: Bool {
        return self.range(of: "\\p{Han}", options: .regularExpression) != nil
    }
}


extension Date {
    var ticks: UInt64 {
        return UInt64((self.timeIntervalSince1970 + 62_135_596_800) * 10_000_000)
    }
    
    var ticksString: String {
        return String(ticks)
    }
}


extension UIImage {
    class func imageFrom(sampleBuffer: CMSampleBuffer?) -> UIImage? {
        if let sampleBuffer = sampleBuffer ,let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let width = CVPixelBufferGetWidth(imageBuffer)
            let height = CVPixelBufferGetHeight(imageBuffer)
            
            let rect = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
            
            let ciImage = CIImage(cvPixelBuffer: imageBuffer)
            let ciContext = CIContext(options: nil)
            if let cgImage = ciContext.createCGImage(ciImage, from: rect) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return nil
        
    }
    
    func pixelBuffer() -> CVPixelBuffer? {
        //Reference: https://github.com/cieslak/CoreMLCrap/blob/master/MachineLearning/ViewController.swift#L42
        var pixelBuffer : CVPixelBuffer?
//        let imageDimension : CGFloat = 299.0
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let imageSize = CGSize(width:self.size.width, height:self.size.height)
        let imageRect = CGRect(origin: CGPoint(x:0, y:0), size: imageSize)
        
        let options = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                       kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        
        UIGraphicsBeginImageContextWithOptions(imageSize, true, 1.0)
        self.draw(in:imageRect)
        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        UIGraphicsEndImageContext()
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(newImage.size.width),
                                         Int(newImage.size.height),
                                         kCVPixelFormatType_32ARGB,
                                         options,
                                         &pixelBuffer)
        guard (status == kCVReturnSuccess),
            let uwPixelBuffer = pixelBuffer else {
                return nil
        }
        
        CVPixelBufferLockBaseAddress(uwPixelBuffer,
                                     CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(uwPixelBuffer)
        let context = CGContext(data: pixelData,
                                width: Int(newImage.size.width),
                                height: Int(newImage.size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(uwPixelBuffer),
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        guard let uwContext = context else {
            return nil
        }
        
        uwContext.translateBy(x: 0, y: newImage.size.height)
        uwContext.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(uwContext)
        newImage.draw(in: CGRect(x: 0,
                                 y: 0,
                                 width: newImage.size.width,
                                 height: newImage.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(uwPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        return pixelBuffer
    }
}

extension CVPixelBuffer {
    func copy() -> CVPixelBuffer {
        precondition(CFGetTypeID(self) == CVPixelBufferGetTypeID(), "copy() cannot be called on a non-CVPixelBuffer")
        var _copy: CVPixelBuffer?
        
        CVPixelBufferCreate(nil,
                            CVPixelBufferGetWidth(self),
                            CVPixelBufferGetHeight(self),
                            CVPixelBufferGetPixelFormatType(self),
                            CVBufferGetAttachments(self, .shouldPropagate),
                            &_copy)
        
        guard let copy = _copy else {
            fatalError()
        }
        CVPixelBufferLockBaseAddress(self, .readOnly)
        CVPixelBufferLockBaseAddress(copy, CVPixelBufferLockFlags(rawValue: 0))
        
        for plane in 0..<CVPixelBufferGetPlaneCount(self) {
            let dest = CVPixelBufferGetBaseAddressOfPlane(copy, plane)
            let source = CVPixelBufferGetBaseAddressOfPlane(self, plane)
            let height = CVPixelBufferGetHeightOfPlane(self, plane)
            let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(self, plane)
            
            memcpy(dest, source, height * bytesPerRow)
        }
        
        CVPixelBufferUnlockBaseAddress(copy, CVPixelBufferLockFlags(rawValue: 0))
        CVPixelBufferUnlockBaseAddress(self, .readOnly)
        return copy
    }
    
    func croppedTo(width: Int, height: Int) -> CVPixelBuffer {
        CVPixelBufferLockBaseAddress(self, .readOnly)
        
        let baseAddress = CVPixelBufferGetBaseAddress(self)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(self)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        
        CVPixelBufferUnlockBaseAddress(self, .readOnly)
        
        // create image
        let cgImage: CGImage = context!.makeImage()!
        let image = UIImage(cgImage: cgImage)
        return image.pixelBuffer()!
    }
}
