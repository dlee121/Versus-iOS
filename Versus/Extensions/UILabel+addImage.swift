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
    func addImage(imageName: String, imageHeight: CGFloat)
    {
        let attachment:NSTextAttachment = NSTextAttachment()
        attachment.image = UIImage(named: imageName)
        attachment.setImageHeight(height: imageHeight)
        //attachment.bounds = CGRect(x: 0.0, y: self.font.descender, width: attachment.image!.size.width, height: attachment.image!.size.height)
        
        let attachmentString:NSAttributedString = NSAttributedString(attachment: attachment)
        let myString:NSMutableAttributedString = NSMutableAttributedString(string: self.text!)
        myString.append(attachmentString)
        
        self.attributedText = myString
    }
    
    func setSelectedCategoryLabel(imageName: String, imageHeight: CGFloat, suffix : String) {
        if self.text!.isEmpty {
            self.text = ""
        }
        let attachment:NSTextAttachment = NSTextAttachment()
        attachment.image = UIImage(named: imageName)
        //attachment.setImageHeight(height: imageHeight)
        attachment.bounds = CGRect(x: 0.0, y: self.font.descender*2, width: imageHeight, height: imageHeight)
        
        let attachmentString:NSAttributedString = NSAttributedString(attachment: attachment)
        let myString:NSMutableAttributedString = NSMutableAttributedString(string: self.text!)
        myString.append(attachmentString)
        myString.append(NSAttributedString(string: suffix))
        
        
        let attachment2:NSTextAttachment = NSTextAttachment()
        attachment2.image = UIImage(named: "close")
        attachment2.bounds = CGRect(x: 0.0, y: self.font.descender/2, width: imageHeight/2, height: imageHeight/2)
        let attachmentString2:NSAttributedString = NSAttributedString(attachment: attachment2)
        myString.append(attachmentString2)
        
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
