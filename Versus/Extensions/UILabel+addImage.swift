//
//  UILabel+addImage.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/14/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import Foundation

extension UILabel
{
    func addImage(imageName: String)
    {
        let attachment:NSTextAttachment = NSTextAttachment()
        attachment.image = UIImage(named: imageName)
        attachment.setImageHeight(height: 24)
        
        let attachmentString:NSAttributedString = NSAttributedString(attachment: attachment)
        let myString:NSMutableAttributedString = NSMutableAttributedString(string: self.text!)
        myString.append(attachmentString)
        
        self.attributedText = myString
    }
}

extension NSTextAttachment {
    func setImageHeight(height: CGFloat) {
        guard let image = image else { return }
        let ratio = image.size.width / image.size.height
        
        bounds = CGRect(x: bounds.origin.x, y: bounds.origin.y-4, width: ratio * height, height: height)
    }
}
