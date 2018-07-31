//
//  MyCircleTableViewCell.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/30/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class MyCircleTableViewCell: UITableViewCell {
    
    @IBOutlet weak var postProfile: UIImageView!
    @IBOutlet weak var postAuthor: UILabel!
    @IBOutlet weak var postVotes: UILabel!
    @IBOutlet weak var question: UILabel!
    @IBOutlet weak var commentAuthor: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var content: UILabel!
    @IBOutlet weak var hearts: UILabel!
    @IBOutlet weak var brokenhearts: UILabel!
    @IBOutlet weak var replyButton: UIButton!

    func setCell(comment : VSComment, postInfo : VSPostQMultiModel_docs_item__source){
        if postInfo != nil {
            postAuthor.text = postInfo.a
            postVotes.text = "\(postInfo.rc!.intValue + postInfo.bc!.intValue) votes"
            question.text = postInfo.q
        }
        
        
        commentAuthor.text = comment.author
        time.text = getTimeString(time: comment.time)
        content.text = comment.content
        hearts.text = "\(comment.upvotes) "
        hearts.addImage(imageName: "heart_red", imageHeight: 18)
        brokenhearts.text = "\(comment.downvotes) "
        brokenhearts.addImage(imageName: "brokenheart_blue", imageHeight: 18)
        
        
    }
    
    func setCell(comment : VSComment){
        
        commentAuthor.text = comment.author
        time.text = getTimeString(time: comment.time)
        content.text = comment.content
        hearts.text = "\(comment.upvotes) "
        hearts.addImage(imageName: "heart_red", imageHeight: 18)
        brokenhearts.text = "\(comment.downvotes) "
        brokenhearts.addImage(imageName: "brokenheart_blue", imageHeight: 18)
        
        
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

}
