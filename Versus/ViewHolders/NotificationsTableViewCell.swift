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
            secondImage.image = nil
            body.text = item.body
            time.text = item.getTimeString()
            
            break
        case TYPE_V:
            break
        case TYPE_R:
            break
        case TYPE_F:
            secondImage.image = nil
            body.text = item.body
            time.text = item.getTimeString()
            break
        case TYPE_M:
            break
        case TYPE_EM:
            break
        default:
            break
        }
        
        
        
    }

    
    
}
