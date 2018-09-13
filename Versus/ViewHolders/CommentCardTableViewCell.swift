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
    @IBOutlet weak var seeMoreButton: UIButton!
    @IBOutlet weak var viewMoreReplies: UIButton!
    @IBOutlet weak var sortButton: UILabel!
    
    @IBOutlet weak var medalView: UILabel!
    
    @IBOutlet weak var leftMargin: NSLayoutConstraint!
    
    @IBOutlet weak var viewMoreHeight: NSLayoutConstraint!
    @IBOutlet weak var viewMoreRepliesCenter: NSLayoutConstraint!
    @IBOutlet weak var replyButtonTrailing: NSLayoutConstraint! //0 or 16
    @IBOutlet weak var seeMoreWidth: NSLayoutConstraint! //0 or 66
    
    @IBOutlet weak var medalViewWidth: NSLayoutConstraint!
    @IBOutlet weak var medalTrailing: NSLayoutConstraint!
    
    
    let none = 0
    let upvoted = 1
    let downvoted = 2
    var commentVote : Int! //0 = none, 1 = hearted, 2 = brokenhearted
    
    var currentComment : VSComment!
    var delegate:PostPageDelegator!
    var rowNumber : Int!
    
    
    func setCell(comment : VSComment, indent : CGFloat, row : Int){
        currentComment = comment
        author.text = comment.author
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
        
        hearts.text = "\(comment.upvotes)"
        brokenhearts.text = "\(comment.downvotes)"
        heartButton.setImage(#imageLiteral(resourceName: "heart_grey"), for: .normal)
        brokenheartButton.setImage(#imageLiteral(resourceName: "brokenheart_grey"), for: .normal)
        commentVote = none
        leftMargin.constant = indent * 48
        
        rowNumber = row
        
        if let childcount = comment.child_count {
            if childcount > 2 {
                viewMoreRepliesCenter.constant = indent * 24
                viewMoreHeight.constant = 21
                viewMoreReplies.isHidden = false
                
                if childcount == 3 {
                    viewMoreReplies.setTitle("View 1 More Reply", for: .normal)
                }
                else {
                    viewMoreReplies.setTitle("View \(childcount-2) More Replies", for: .normal)
                }
            }
            else {
                viewMoreReplies.isHidden = true
                viewMoreHeight.constant = 0
            }
        }
        else {
            viewMoreReplies.isHidden = true
            viewMoreHeight.constant = 0
        }
        
        if comment.topmedal == 0 {
            medalViewWidth.constant = 0
            medalTrailing.constant = 0
        }
        
    }
    
    func setCellWithSelection(comment : VSComment, indent : CGFloat, hearted : Bool, row : Int){
        currentComment = comment
        author.text = comment.author
        time.text = getTimeString(time: comment.time)
        content.text = comment.content
        
        DispatchQueue.main.async {
            if self.content.isTruncated {
                self.showSeeMore()
            }
            else {
                self.hideSeeMore()
            }
        }
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
        
        rowNumber = row
        
        if let childcount = comment.child_count {
            if childcount > 2 {
                viewMoreRepliesCenter.constant = indent * 24
                viewMoreHeight.constant = 21
                viewMoreReplies.isHidden = false
                
                if childcount == 3 {
                    viewMoreReplies.setTitle("View 1 More Reply", for: .normal)
                }
                else {
                    viewMoreReplies.setTitle("View \(childcount-2) More Replies", for: .normal)
                }
            }
            else {
                viewMoreReplies.isHidden = true
                viewMoreHeight.constant = 0
            }
        }
        else {
            viewMoreReplies.isHidden = true
            viewMoreHeight.constant = 0
        }
        
        if comment.topmedal == 0 {
            medalViewWidth.constant = 0
            medalTrailing.constant = 0
        }
    }
    
    func setTopCardCell(comment : VSComment, row : Int, sortType : String){
        sortButton.setPostPageSortLabel(imageName: "sort_"+sortType, suffix: " "+sortType)
        
        currentComment = comment
        author.text = comment.author
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
        
        hearts.text = "\(comment.upvotes)"
        brokenhearts.text = "\(comment.downvotes)"
        heartButton.setImage(#imageLiteral(resourceName: "heart_grey"), for: .normal)
        brokenheartButton.setImage(#imageLiteral(resourceName: "brokenheart_grey"), for: .normal)
        commentVote = none
        
        rowNumber = row
        
        if comment.topmedal == 0 {
            medalViewWidth.constant = 0
            medalTrailing.constant = 0
        }
    }
    
    func setTopCardCellWithSelection(comment : VSComment, hearted : Bool, row : Int, sortType : String){
        sortButton.setPostPageSortLabel(imageName: "sort_"+sortType, suffix: " "+sortType)
        
        currentComment = comment
        author.text = comment.author
        time.text = getTimeString(time: comment.time)
        content.text = comment.content
        
        DispatchQueue.main.async {
            if self.content.isTruncated {
                self.showSeeMore()
            }
            else {
                self.hideSeeMore()
            }
        }
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
        
        rowNumber = row
        
        if comment.topmedal == 0 {
            medalViewWidth.constant = 0
            medalTrailing.constant = 0
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
    
    @IBAction func heartTapped(_ sender: UIButton) {
        switch commentVote {
        case upvoted:
            heartButton.setImage(#imageLiteral(resourceName: "heart_grey"), for: .normal)
            //currentComment.upvotes -= 1
            commentVote = none
        case downvoted:
            heartButton.setImage(#imageLiteral(resourceName: "heart_red"), for: .normal)
            brokenheartButton.setImage(#imageLiteral(resourceName: "brokenheart_grey"), for: .normal)
            //currentComment.upvotes += 1
            //currentComment.downvotes -= 1
            commentVote = upvoted
        default:
            heartButton.setImage(#imageLiteral(resourceName: "heart_red"), for: .normal)
            brokenheartButton.setImage(#imageLiteral(resourceName: "brokenheart_grey"), for: .normal)
            //currentComment.upvotes += 1
            commentVote = upvoted
        }
        delegate.commentHearted(commentID: currentComment.comment_id)
        hearts.text = "\(currentComment.upvotes)"
        brokenhearts.text = "\(currentComment.downvotes)"
        
    }
    
    @IBAction func brokenheartTapped(_ sender: UIButton) {
        switch commentVote {
        case downvoted:
            brokenheartButton.setImage(#imageLiteral(resourceName: "brokenheart_grey"), for: .normal)
            //currentComment.downvotes -= 1
            commentVote = none
        case upvoted:
            heartButton.setImage(#imageLiteral(resourceName: "heart_grey"), for: .normal)
            brokenheartButton.setImage(#imageLiteral(resourceName: "brokenheart_blue"), for: .normal)
            //currentComment.upvotes -= 1
            //currentComment.downvotes += 1
            commentVote = downvoted
        default:
            heartButton.setImage(#imageLiteral(resourceName: "heart_grey"), for: .normal)
            brokenheartButton.setImage(#imageLiteral(resourceName: "brokenheart_blue"), for: .normal)
            //currentComment.downvotes += 1
            commentVote = downvoted
        }
        delegate.commentBrokenhearted(commentID: currentComment.comment_id)
        hearts.text = "\(currentComment.upvotes)"
        brokenhearts.text = "\(currentComment.downvotes)"
    }
    
    @IBAction func profileTapped(_ sender: UIButton) {
        delegate.goToProfile(profileUsername: currentComment.author)
    }
    
    func showSeeMore() {
        replyButtonTrailing.constant = 16
        seeMoreWidth.constant = 66
    }
    
    func hideSeeMore(){
        replyButtonTrailing.constant = 0
        seeMoreWidth.constant = 0
    }
    
    func setCommentMedal(medalType : String) {
        switch medalType {
        case "g":
            medalView.addImage(imageName: "medalGold", imageHeight: 24)
            if currentComment.topmedal < 3 {
                currentComment.topmedal = 3
            }
        case "s":
            medalView.addImage(imageName: "medalSilver", imageHeight: 24)
            if currentComment.topmedal < 2 {
                currentComment.topmedal = 2
            }
        case "b":
            medalView.addImage(imageName: "medalBronze", imageHeight: 24)
            if currentComment.topmedal < 1 {
                currentComment.topmedal = 1
            }
        default:
            break
        }
        
        medalViewWidth.constant = 24
        medalTrailing.constant = 8
        
    }
    
    func removeMedalView(){
        medalViewWidth.constant = 0
        medalTrailing.constant = 0
    }
    
    @IBAction func seeMoreTapped(_ sender: Any) {
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
    
    @IBAction func replyButtonTapped(_ sender: UIButton) {
        delegate.replyButtonTapped(replyTarget: currentComment, cell: self)
    }
    
    @IBAction func viewMoreTapped(_ sender: UIButton) {
        delegate.viewMoreRepliesTapped(topCardComment: currentComment)
    }
    
    @IBAction func sortButtonTapped(_ sender: UIButton) {
        delegate.presentSortMenu(sortButtonLabel: sortButton)
    }
    
    
    
}
