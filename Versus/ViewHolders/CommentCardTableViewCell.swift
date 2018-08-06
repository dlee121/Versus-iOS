//
//  CommentCardTableViewCell.swift
//  Versus
//
//  Created by Dongkeun Lee on 8/3/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class CommentCardTableViewCell: UITableViewCell {
    
    @IBOutlet weak var author: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var content: UILabel!
    @IBOutlet weak var hearts: UILabel!
    @IBOutlet weak var brokenhearts: UILabel!
    @IBOutlet weak var heartButton: UIButton!
    @IBOutlet weak var brokenheartButton: UIButton!
    
    @IBOutlet weak var leftMargin: NSLayoutConstraint!
    
    let none = 0
    let upvoted = 1
    let downvoted = 2
    var commentVote : Int! //0 = none, 1 = hearted, 2 = brokenhearted
    
    var currentComment : VSComment!
    var delegate:PostPageDelegator!
    
    func setCell(comment : VSComment, indent : CGFloat){
        currentComment = comment
        author.text = comment.author
        time.text = getTimeString(time: comment.time)
        content.text = comment.content
        hearts.text = "\(comment.upvotes)"
        brokenhearts.text = "\(comment.downvotes)"
        heartButton.setImage(#imageLiteral(resourceName: "heart_grey"), for: .normal)
        brokenheartButton.setImage(#imageLiteral(resourceName: "brokenheart_grey"), for: .normal)
        commentVote = none
        leftMargin.constant = indent * 48
    }
    
    func setCellWithSelection(comment : VSComment, indent : CGFloat, hearted : Bool){
        currentComment = comment
        author.text = comment.author
        time.text = getTimeString(time: comment.time)
        content.text = comment.content
        hearts.text = "\(comment.upvotes)"
        brokenhearts.text = "\(comment.downvotes)"
        if hearted {
            heartButton.setImage(#imageLiteral(resourceName: "heart_red"), for: .normal)
            brokenheartButton.setImage(#imageLiteral(resourceName: "brokenheart_grey"), for: .normal)
            commentVote = upvoted
        }
        else {
            heartButton.setImage(#imageLiteral(resourceName: "heart_grey"), for: .normal)
            brokenheartButton.setImage(#imageLiteral(resourceName: "brokenheart_blue"), for: .normal)
            commentVote = downvoted
        }
        
        leftMargin.constant = indent * 48
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
    
    @IBAction func heartTapped(_ sender: UIButton) {
        switch commentVote {
        case upvoted:
            heartButton.setImage(#imageLiteral(resourceName: "heart_grey"), for: .normal)
            commentVote = none
        case downvoted:
            heartButton.setImage(#imageLiteral(resourceName: "heart_red"), for: .normal)
            brokenheartButton.setImage(#imageLiteral(resourceName: "brokenheart_grey"), for: .normal)
            commentVote = upvoted
        default:
            heartButton.setImage(#imageLiteral(resourceName: "heart_red"), for: .normal)
            brokenheartButton.setImage(#imageLiteral(resourceName: "brokenheart_grey"), for: .normal)
            commentVote = upvoted
        }
        delegate.commentHearted(commentID: currentComment.comment_id)
        
    }
    
    @IBAction func brokenheartTapped(_ sender: UIButton) {
        switch commentVote {
        case downvoted:
            brokenheartButton.setImage(#imageLiteral(resourceName: "brokenheart_grey"), for: .normal)
            commentVote = none
        case upvoted:
            heartButton.setImage(#imageLiteral(resourceName: "heart_grey"), for: .normal)
            brokenheartButton.setImage(#imageLiteral(resourceName: "brokenheart_blue"), for: .normal)
            commentVote = downvoted
        default:
            heartButton.setImage(#imageLiteral(resourceName: "heart_grey"), for: .normal)
            brokenheartButton.setImage(#imageLiteral(resourceName: "brokenheart_blue"), for: .normal)
            commentVote = downvoted
        }
        delegate.commentBrokenhearted(commentID: currentComment.comment_id)
    }
    
    

}
