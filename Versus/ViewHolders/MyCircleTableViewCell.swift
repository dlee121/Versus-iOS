//
//  MyCircleTableViewCell.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/30/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import Nuke
import AWSS3

class MyCircleTableViewCell: UITableViewCell {
    
    @IBOutlet weak var postProfile: UIImageView!
    @IBOutlet weak var postAuthor: UILabel!
    @IBOutlet weak var postVotes: UILabel!
    @IBOutlet weak var question: UILabel!
    @IBOutlet weak var commentProfile: UIImageView!
    @IBOutlet weak var commentAuthor: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var content: UILabel!
    @IBOutlet weak var hearts: UILabel!
    @IBOutlet weak var brokenhearts: UILabel!
    @IBOutlet weak var replyCount: UILabel!
    @IBOutlet weak var seeMoreButton: UIButton!
    @IBOutlet weak var medalView: UILabel!
    
    @IBOutlet weak var seeMoreWidth: NSLayoutConstraint!
    @IBOutlet weak var replyButtonTrailing: NSLayoutConstraint!
    
    @IBOutlet weak var medalTrailing: NSLayoutConstraint!
    @IBOutlet weak var medalWidth: NSLayoutConstraint!
    @IBOutlet weak var replyButtonWidth: NSLayoutConstraint!
    
    var commentID : String!
    
    var delegate:MyCircleDelegator!
    var rowNumber : Int!
    
    
    func setCell(comment : VSComment, postInfo : VSPostQMultiModel_docs_item__source, row : Int){
        if postInfo != nil {
            postAuthor.text = postInfo.a
            postVotes.text = "\(postInfo.rc!.intValue + postInfo.bc!.intValue) votes"
            question.text = postInfo.q
        }
        
        commentID = comment.comment_id
        
        commentAuthor.text = comment.author
        time.text = getTimeString(time: comment.time)
        content.text = comment.content
        
        DispatchQueue.main.async {
            if self.content.isTruncated || self.content.numberOfLines == 0{ //if content is truncated, or if numberOfLines == 0 which See More was tapped
                self.showSeeMore()
            }
            else {
                self.hideSeeMore()
            }
        }
        
        if comment.topmedal > 0 {
            showMedal(medalType: comment.topmedal)
        }
        else {
            hideMedal()
        }
        
        hearts.text = "\(comment.upvotes) "
        hearts.addImage(imageName: "heart_red", imageHeight: 18)
        brokenhearts.text = "\(comment.downvotes) "
        brokenhearts.addImage(imageName: "brokenheart_blue", imageHeight: 18)
        replyCount.text = "\(comment.replyCount!) "
        replyCount.addImage(imageName: "ic_reply_count", imageHeight: 18)
        
        rowNumber = row
    }
    
    func setCell(comment : VSComment, row : Int){
        
        commentAuthor.text = comment.author
        time.text = getTimeString(time: comment.time)
        content.text = comment.content
        
        DispatchQueue.main.async {
            if self.content.isTruncated || self.content.numberOfLines == 0{ //if content is truncated, or if numberOfLines == 0 which See More was tapped
                self.showSeeMore()
            }
            else {
                self.hideSeeMore()
            }
        }
        
        if comment.topmedal > 0 {
            showMedal(medalType: comment.topmedal)
        }
        else {
            hideMedal()
        }
        
        hearts.text = "\(comment.upvotes) "
        hearts.addImage(imageName: "heart_red", imageHeight: 18)
        brokenhearts.text = "\(comment.downvotes) "
        brokenhearts.addImage(imageName: "brokenheart_blue", imageHeight: 18)
        replyCount.text = "\(comment.replyCount!) "
        replyCount.addImage(imageName: "ic_reply_count", imageHeight: 18)
        
        rowNumber = row
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
        if profileImageVersion == 0 {
            DispatchQueue.main.async {
                self.postProfile.image = #imageLiteral(resourceName: "default_profile")
                self.postProfile.layer.cornerRadius = self.postProfile.frame.size.height / 2
                self.postProfile.clipsToBounds = true
            }
        }
        else {
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
                    Nuke.loadImage(with: presignedURL!.absoluteURL!, into: self.postProfile)
                    self.postProfile.layer.cornerRadius = self.postProfile.frame.size.height / 2
                    self.postProfile.clipsToBounds = true
                }
                
                return nil
            }
        }
    }
    
    func setCommentProfileImage(username : String, profileImageVersion : Int){
        if profileImageVersion == 0 {
            DispatchQueue.main.async {
                self.commentProfile.image = #imageLiteral(resourceName: "default_profile")
                self.commentProfile.layer.cornerRadius = self.commentProfile.frame.size.height / 2
                self.commentProfile.clipsToBounds = true
            }
        }
        else {
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
                    Nuke.loadImage(with: presignedURL!.absoluteURL!, into: self.commentProfile)
                    self.commentProfile.layer.cornerRadius = self.commentProfile.frame.size.height / 2
                    self.commentProfile.clipsToBounds = true
                }
                
                return nil
            }
        }
    }
    
    func showSeeMore() {
        replyButtonTrailing.constant = 16
        seeMoreWidth.constant = 66
    }
    
    func hideSeeMore(){
        replyButtonTrailing.constant = 0
        seeMoreWidth.constant = 0
    }
    
    @IBAction func seeMoreTapped(_ sender: UIButton) {
        if content.numberOfLines == 0 {
            delegate.beginUpdates()
            content.numberOfLines = 2
            seeMoreButton.setTitle("See More", for: .normal)
            delegate.endUpdatesForSeeLess(row: rowNumber)
            
        }
        else {
            delegate.beginUpdatesForSeeMore(row: rowNumber)
            content.numberOfLines = 0
            seeMoreButton.setTitle("See Less", for: .normal)
            delegate.endUpdates()
            
        }
    }
    
    @IBAction func overflowTapped(_ sender: UIButton) {
        delegate.overflowTapped(commentID: commentID, sender: sender, rowNumber: rowNumber)
    }
    
    
    
    @IBAction func replyButtonTapped(_ sender: UIButton) {
        delegate.replyButtonTapped(row: rowNumber)
    }
    
    @IBAction func postProfileTapped(_ sender: UIButton) {
        if postAuthor.text!.lowercased() != "deleted" {
            delegate.goToProfile(username: postAuthor.text!)
        }
    }
    
    @IBAction func commentProfileImgTapped(_ sender: UIButton) {
        if commentAuthor.text!.lowercased() != "deleted" {
            delegate.goToProfile(username: commentAuthor.text!)
        }
    }
    
    @IBAction func commentUsernameTapped(_ sender: UIButton) {
        delegate.goToProfile(username: commentAuthor.text!)
    }
    
    func showMedal(medalType : Int){
        
        switch medalType {
        case 3:
            medalView.addImage(imageName: "medalGold", imageHeight: 18)
        case 2:
            medalView.addImage(imageName: "medalSilver", imageHeight: 18)
        case 1:
            medalView.addImage(imageName: "medalBronze", imageHeight: 18)
        default:
            break
        }
        
        medalTrailing.constant = 10
        medalWidth.constant = 18
    }
    
    func hideMedal(){
        medalTrailing.constant = 0
        medalWidth.constant = 0
    }
    
    
    
    
    

}
