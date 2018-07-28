//
//  FGHTableViewCell.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/26/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import Nuke
import AWSS3

class FGHTableViewCell: UITableViewCell {

    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var usernameView: UILabel!
    
    
    
    func setCell(username : String, profileImageVersion : Int){
        usernameView.text = username
        
        self.profileImage.layer.cornerRadius = self.profileImage.frame.size.height / 2
        self.profileImage.clipsToBounds = true
        
        if profileImageVersion > 0 {
            print("got piv")
            setProfileImage(username: username, profileImageVersion: profileImageVersion)
        }
        else {
            print("got 0")
            profileImage.image = #imageLiteral(resourceName: "default_profile")
        }
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
            DispatchQueue.main.async {
                Nuke.loadImage(with: presignedURL!.absoluteURL!, into: self.profileImage)
            }
            
            return nil
        }
    }

}
