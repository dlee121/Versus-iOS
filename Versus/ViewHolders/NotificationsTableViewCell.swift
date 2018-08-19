//
//  NotificationsTableViewCell.swift
//  Versus
//
//  Created by Dongkeun Lee on 8/17/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class NotificationsTableViewCell: UITableViewCell {
    
    
    
    @IBOutlet weak var secondImage: UIImageView!
    @IBOutlet weak var body: UILabel!
    @IBOutlet weak var time: UILabel!
    
    @IBOutlet weak var secondImageTop: NSLayoutConstraint!
    @IBOutlet weak var secondImageHeight: NSLayoutConstraint!
    
    let TYPE_U = 0 //new comment upvote notification
    let TYPE_C = 1 //new comment reply notification
    let TYPE_V = 2 //new post vote notification
    let TYPE_R = 3 //new post root comment notification
    let TYPE_F = 4 //new follower notification
    let TYPE_M = 5 //new medal notification
    let TYPE_EM = 6 //for password reset email setup notification
    
    func setCell(item : NotificationItem){
        switch item.type! {
        case TYPE_U:
            break
        case TYPE_C:
            hideSecondImage()
            body.text = item.body
            time.text = item.getTimeString()
            
        case TYPE_V:
            break
        case TYPE_R:
            hideSecondImage()
            body.text = item.body
            time.text = item.getTimeString()
            
            break
        case TYPE_F:
            hideSecondImage()
            body.text = item.body
            time.text = item.getTimeString()
            
        case TYPE_M:
            switch item.medalType {
            case "g":
                secondImage.image = #imageLiteral(resourceName: "medalGold")
                showSecondImage()
            case "s":
                secondImage.image = #imageLiteral(resourceName: "medalSilver")
                showSecondImage()
            case "b":
                secondImage.image = #imageLiteral(resourceName: "medalBronze")
                showSecondImage()
            default:
                hideSecondImage()
            }
            body.text = item.body
            time.text = item.getTimeString()
            
        case TYPE_EM:
            break
        default:
            break
        }
        
        
        
    }
    
    func showSecondImage(){
        secondImageHeight.constant = 42
        secondImageTop.constant = 8
    }
    
    func hideSecondImage(){
        secondImageHeight.constant = 0
        secondImageTop.constant = 0
        secondImage.image = nil
        
    }

    
    
}
