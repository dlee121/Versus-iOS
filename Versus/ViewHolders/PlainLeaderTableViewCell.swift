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
    
    @IBOutlet weak var rank: UILabel!
    
    
    func setCell(item : LeaderboardEntry, rankNumber : Int){
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
        
        rank.text = "\(rankNumber)"
        
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
