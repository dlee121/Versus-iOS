//
//  GoldLeaderTableViewCell.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/13/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import AWSS3
import Nuke

class GoldLeaderTableViewCell: UITableViewCell {

    
    @IBOutlet weak var profileImage: UIButton!
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
            profileImage.setImage(#imageLiteral(resourceName: "default_profile"), for: .normal)
        }
        DispatchQueue.main.async {
            self.profileImage.layer.cornerRadius = self.profileImage.frame.size.height / 2
            self.profileImage.clipsToBounds = true
        }
        
        username.text = item.username
        influence.text = "\(item.influence) influence"
        goldCount.text = "\(item.g)"
        goldCount.addImage(imageName: "medalGold", imageHeight: 24)
        silverCount.text = "\(item.s)"
        silverCount.addImage(imageName: "medalSilver", imageHeight: 24)
        bronzeCount.text = "\(item.b)"
        bronzeCount.addImage(imageName: "medalBronze", imageHeight: 24)
        
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
            ImagePipeline.shared.loadImage(with: presignedURL!.absoluteURL!) { response, _ in
                self.profileImage.setImage(response?.image, for: .normal)
            }
            
            return nil
        }
        
    }

}

