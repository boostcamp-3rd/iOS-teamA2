//
//  NSAttributedString+UIImage.swift
//  OneDay
//
//  Created by juhee on 13/02/2019.
//  Copyright © 2019 teamA2. All rights reserved.
//

import UIKit

extension NSAttributedString {
    var firstImage: UIImage? {
        let range = NSRange(location: 0, length: self.length)
        var result: UIImage?
        self.enumerateAttributes(in: range, options: NSAttributedString.EnumerationOptions(rawValue: 0)) { (object, range, stop) in
            if object.keys.contains(NSAttributedString.Key.attachment) {
                if let attachment = object[NSAttributedString.Key.attachment] as? NSTextAttachment {
                    if let image = attachment.image {
                        result = image
                        stop.pointee = true
                    } else if let image = attachment.image(forBounds: attachment.bounds, textContainer: nil, characterIndex: range.location) {
                        result = image
                        stop.pointee = true
                    }
                }
            }
        }
        return result
    }
}

extension UIImage {
    var attributedString: NSAttributedString {
        let textAttachment = NSTextAttachment()
        textAttachment.image = self
        let attrStringWithImage = NSAttributedString(attachment: textAttachment)
        let mutable = NSMutableAttributedString(attributedString: attrStringWithImage)
        mutable.append(NSAttributedString(string: "\n\n"))
        return mutable
    }
    
    func saveToFile(fileName: String) -> String? {
        guard let data = self.jpegData(compressionQuality: 0.8) else {
            return nil
        }

        guard let urlForDataStorage = fileName.urlForDataStorage else { return nil }
        
        do {
            try data.write(to: urlForDataStorage)
            return fileName
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
}
