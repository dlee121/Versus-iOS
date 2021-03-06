//
//  PostTextCollectionViewCell.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/5/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import Nuke
import AWSS3

class PostTextTableViewCell: UITableViewCell {
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var votecountLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var rednameLabel: UILabel!
    @IBOutlet weak var blacknameLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    var postID : String!
    var rowNumber : Int!
    
    var delegate : ProfileDelegator!
    
    
    func setCell(post : PostObject, vIsRed : Bool, row : Int){
        postID = post.post_id
        rowNumber = row
        
        authorLabel.text = post.author
        votecountLabel.text = "\(post.redcount.intValue + post.blackcount.intValue) votes"
        categoryLabel.text = getCategoryString(categoryInt: post.category)
        timeLabel.text = getTimeString(time: post.time)
        
        //set up profile image
        
        questionLabel.text = post.question
        
        rednameLabel.text = post.redname
        blacknameLabel.text = post.blackname
        
        if post.profileImageVersion > 0 {
            setProfileImage(username: post.author, profileImageVersion: post.profileImageVersion)
            
        }
        else {
            profileImage.image = UIImage(named: "default_profile")
        }
        DispatchQueue.main.async {
            self.profileImage.layer.cornerRadius = self.profileImage.frame.size.height / 2
            self.profileImage.clipsToBounds = true
        }
        
    }
    
    func getCategoryString(categoryInt : NSNumber) -> String {
        switch categoryInt {
        case 0:
            return "Automobiles"
        case 1:
            return "Cartoon/Anime/Fiction"
        case 2:
            return "Celebrity/Gossip"
        case 3:
            return "Culture"
        case 4:
            return "Education"
        case 5:
            return "Electronics"
        case 6:
            return "Fashion"
        case 7:
            return "Finance"
        case 8:
            return "Food/Restaurant"
        case 9:
            return "Game/Entertainment"
        case 10:
            return "Morality/Ethics/Law"
        case 11:
            return "Movies/TV"
        case 12:
            return "Music/Artists"
        case 13:
            return "Politics"
        case 14:
            return "Random"
        case 15:
            return "Religion"
        case 16:
            return "Science"
        case 17:
            return "Social Issues"
        case 18:
            return "Sports"
        case 19:
            return "Technology"
        case 20:
            return "Weapons"
        case 42069:
            return "NATIVE APP INSTALL AD"
        case 69420:
            return "NATIVE CONTENT AD"
        default:
            return "N/A"
        }
    }
    
    func getTimeString(time : String) -> String {
        var timeFormat = 0
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let inputDate = formatter.date(from: time)
        var timediff = Int(Date().timeIntervalSince(inputDate!))
        
        //time format constants: 0 = seconds, 1 = minutes, 2 = hours, 3 = days , 4 = weeks, 5 = months, 6 = years
        if timediff >= 60 {  //if 60 seconds or more, convert to minutes
            timediff /= 60
            timeFormat = 1
            if timediff >= 60 { //if 60 minutes or more, convert to hours
                timediff /= 60
                timeFormat = 2
                if timediff >= 24 { //if 24 hours or more, convert to days
                    timediff /= 24
                    timeFormat = 3
                    
                    if timediff >= 365 { //if 365 days or more, convert to years
                        timediff /= 365
                        timeFormat = 6
                    }
                        
                    else if timeFormat < 6 && timediff >= 30 { //if 30 days or more and not yet converted to years, convert to months
                        timediff /= 30
                        timeFormat = 5
                    }
                        
                    else if timeFormat < 5 && timediff >= 7 { //if 7 days or more and not yet converted to months or years, convert to weeks
                        timediff /= 7
                        timeFormat = 4
                    }
                    
                }
            }
        }
        
        
        if timediff > 1 { //if timediff is not a singular value
            timeFormat += 7
        }
        
        switch timeFormat {
        //plural
        case 7:
            return "\(timediff)" + " seconds ago"
        case 8:
            return "\(timediff)" + " minutes ago"
        case 9:
            return "\(timediff)" + " hours ago"
        case 10:
            return "\(timediff)" + " days ago"
        case 11:
            return "\(timediff)" + " weeks ago"
        case 12:
            return "\(timediff)" + " months ago"
        case 13:
            return "\(timediff)" + " years ago"
            
        //singular
        case 0:
            return "\(timediff)" + " second ago"
        case 1:
            return "\(timediff)" + " minute ago"
        case 2:
            return "\(timediff)" + " hour ago"
        case 3:
            return "\(timediff)" + " day ago"
        case 4:
            return "\(timediff)" + " week ago"
        case 5:
            return "\(timediff)" + " month ago"
        case 6:
            return "\(timediff)" + " year ago"
            
        default:
            return ""
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
    
    @IBAction func profileTapped(_ sender: UIButton) {
        if authorLabel.text!.lowercased() != "deleted" {
            delegate.goToProfile(username: authorLabel.text!)
        }
    }
    
    @IBAction func overflowTapped(_ sender: UIButton) {
        delegate.overflowTapped(postID: postID, sender: sender, rowNumber: rowNumber)        
    }
    
    
}

