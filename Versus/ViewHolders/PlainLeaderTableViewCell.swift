//
//  PlainLeaderTableViewCell.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/13/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import AWSS3
import Nuke

class PlainLeaderTableViewCell: UITableViewCell {

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var influence: UILabel!
    @IBOutlet weak var goldCount: UILabel!
    @IBOutlet weak var silverCount: UILabel!
    @IBOutlet weak var bronzeCount: UILabel!
    
    
    
    func setCell(item : LeaderboardEntry){
        if item.pi > 0 {
            setProfileImage(username: item.username, profileImageVersion: item.pi)
        }
        else{
            profileImage.image = #imageLiteral(resourceName: "default_profile")
        }
        profileImage.layer.cornerRadius = profileImage.frame.size.height / 2
        profileImage.clipsToBounds = true
        
        username.text = item.username
        influence.text = "\(item.influence) influence"
        goldCount.text = "\(item.g)"
        goldCount.addImage(imageName: "medalGold")
        silverCount.text = "\(item.s)"
        silverCount.addImage(imageName: "medalSilver")
        bronzeCount.text = "\(item.b)"
        bronzeCount.addImage(imageName: "medalBronze")
        
    }
    
    func setProfileImage(username : String, profileImageVersion : Int){
        let request = AWSS3GetPreSignedURLRequest()
        request.expires = Date().addingTimeInterval(86400)
        request.bucket = "versus.profile-pictures"
        request.httpMethod = .GET
        request.key = username + "-\(profileImageVersion).jpeg"
        
        AWSS3PreSignedURLBuilder.default().getPreSignedURL(request).continueWith { (task:AWSTask<NSURL>) -> Any? in
            if let error = task.error {
                print("Error: \(error)")
                return nil
            }
            
            let presignedURL = task.result
            Nuke.loadImage(with: presignedURL!.absoluteURL!, into: self.profileImage)
            
            return nil
        }
    }
}

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
