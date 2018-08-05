//
//  PostCardTableViewCell.swift
//  Versus
//
//  Created by Dongkeun Lee on 8/3/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import AWSS3
import Nuke

class PostCardTableViewCell: UITableViewCell {

    @IBOutlet weak var question: UILabel!
    @IBOutlet weak var redname: UILabel!
    @IBOutlet weak var bluename: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var author: UILabel!
    @IBOutlet weak var votecount: UILabel!
    @IBOutlet weak var redImage: UIImageView!
    @IBOutlet weak var blueImage: UIImageView!
    @IBOutlet weak var sortButton: UILabel!
    
    @IBOutlet weak var sortContainerTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var redWidth: NSLayoutConstraint!
    @IBOutlet weak var bluePercent: UILabel!
    @IBOutlet weak var redPercent: UILabel!
    @IBOutlet weak var graphBar: UIView!
    @IBOutlet weak var redCheck: UIImageView!
    @IBOutlet weak var blueCheck: UIImageView!
    @IBOutlet weak var leftOverlay: UIView!
    @IBOutlet weak var rightOverlay: UIView!
    
    
    
    let DEFAULT = 0
    let S3 = 1
    let getPreSignedURLRequest = AWSS3GetPreSignedURLRequest()
    
    var currentPost : PostObject!
    
    func setCell(post : PostObject, votedSide : String){
        print("setting up post card")
        
        currentPost = post
        question.text = post.question
        redname.text = post.redname
        bluename.text = post.blackname
        if post.profileImageVersion > 0 {
            setProfileImage(username: post.author, profileImageVersion: post.profileImageVersion)
        }
        else {
            profileImage.image = #imageLiteral(resourceName: "default_profile")
        }
        author.text = post.author
        votecount.text = "\(post.redcount.intValue+post.blackcount.intValue) votes"
        if post.redimg.intValue % 10 == S3 {
            getPostImage(postID: post.post_id, lORr: 0, editVersion: post.redimg.intValue / 10)
        }
        
        if post.blackimg.intValue % 10 == S3 {
            getPostImage(postID: post.post_id, lORr: 1, editVersion: post.blackimg.intValue / 10)
        }
        
        switch votedSide {
        case "none":
            sortContainerTopConstraint.constant = 8
            bluePercent.isHidden = true
            redPercent.isHidden = true
            graphBar.isHidden = true
            redCheck.isHidden = true
            blueCheck.isHidden = true
            leftOverlay.alpha = 0
            rightOverlay.alpha = 0
        case "RED":
            sortContainerTopConstraint.constant = 32.5
            bluePercent.isHidden = false
            redPercent.isHidden = false
            graphBar.isHidden = false
            calculateGraph()
            redCheck.isHidden = false
            blueCheck.isHidden = true
            leftOverlay.alpha = 0.3
            rightOverlay.alpha = 0
        case "BLK":
            sortContainerTopConstraint.constant = 32.5
            bluePercent.isHidden = false
            redPercent.isHidden = false
            graphBar.isHidden = false
            calculateGraph()
            redCheck.isHidden = true
            blueCheck.isHidden = false
            leftOverlay.alpha = 0
            rightOverlay.alpha = 0.3
        default:
            sortContainerTopConstraint.constant = 8
            bluePercent.isHidden = true
            redPercent.isHidden = true
            graphBar.isHidden = true
            redCheck.isHidden = true
            blueCheck.isHidden = true
            leftOverlay.alpha = 0
            rightOverlay.alpha = 0
        }
        
    }
    
    func calculateGraph(){
        let redcount = currentPost.redcount.intValue
        let bluecount = currentPost.blackcount.intValue
        let totalVotes =  redcount + bluecount
        
        let redPercentage = (redcount * 100) / totalVotes
        let bluePercentage = (bluecount * 100) / totalVotes
        
        redPercent.text = "\(redPercentage)%"
        bluePercent.text = "\(bluePercentage)%"
        
        let redLength = CGFloat(currentPost.redcount.floatValue / Float(totalVotes)) * UIScreen.main.bounds.width
        redWidth.constant = redLength
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
    
    func getPostImage(postID : String, lORr : Int, editVersion : Int){
        let request = AWSS3GetPreSignedURLRequest()
        request.expires = Date().addingTimeInterval(86400)
        request.bucket = "versus.pictures"
        request.httpMethod = .GET
        
        if lORr == 0 { //left
            if editVersion == 0 {
                request.key = postID + "-left.jpeg"
            }
            else{
                request.key = postID + "-left\(editVersion).jpeg"
            }
            
            AWSS3PreSignedURLBuilder.default().getPreSignedURL(request).continueWith { (task:AWSTask<NSURL>) -> Any? in
                if let error = task.error {
                    print("Error: \(error)")
                    return nil
                }
                
                let presignedURL = task.result
                DispatchQueue.main.async {
                    Nuke.loadImage(with: presignedURL!.absoluteURL!, into: self.redImage)
                }
                
                return nil
            }
        }
        else { //right
            if editVersion == 0 {
                request.key = postID + "-right.jpeg"
            }
            else{
                request.key = postID + "-right\(editVersion).jpeg"
            }
            
            AWSS3PreSignedURLBuilder.default().getPreSignedURL(request).continueWith { (task:AWSTask<NSURL>) -> Any? in
                if let error = task.error {
                    print("Error: \(error)")
                    return nil
                }
                
                let presignedURL = task.result
                DispatchQueue.main.async {
                    Nuke.loadImage(with: presignedURL!.absoluteURL!, into: self.blueImage)
                }
                
                return nil
            }
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