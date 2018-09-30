//
//  NotificationsTableViewCell.swift
//  Versus
//
//  Created by Dongkeun Lee on 8/17/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class NotificationsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var body: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var notificationContainer: UIView!
    
    @IBOutlet weak var notificationIcon: UIImageView!
    
    
    let TYPE_U = 0 //new comment upvote notification
    let TYPE_C = 1 //new comment reply notification
    let TYPE_V = 2 //new post vote notification
    let TYPE_R = 3 //new post root comment notification
    let TYPE_F = 4 //new follower notification
    let TYPE_M = 5 //new medal notification
    let TYPE_EM = 6 //for password reset email setup notification
    
    var delegate : NotificationsDelegator!
    var subpath : String!
    var rowNumber : Int!
    
    func setCell(item : NotificationItem, row : Int){
        rowNumber = row
        
        switch item.type! {
        case TYPE_U:
            notificationIcon.image = #imageLiteral(resourceName: "heart_red")
            body.text = item.body
            time.text = item.getTimeString()
            subpath = "u/\(item.key!)"
            
        case TYPE_C:
            body.text = item.body
            time.text = item.getTimeString()
            subpath = "c/\(item.key!)"
            
        case TYPE_V:
            body.text = item.body
            time.text = item.getTimeString()
            subpath = "v/\(item.key!)"
            
        case TYPE_R:
            body.text = item.body
            time.text = item.getTimeString()
            subpath = "r/\(item.key!)"
            
        case TYPE_F:
            body.text = item.body
            time.text = item.getTimeString()
            subpath = "f"
            
        case TYPE_M:
            switch item.medalType {
            case "g":
                notificationIcon.image = #imageLiteral(resourceName: "medalGold")
            case "s":
                notificationIcon.image = #imageLiteral(resourceName: "medalSilver")
            case "b":
                notificationIcon.image = #imageLiteral(resourceName: "medalBronze")
            default:
                break
            }
            body.text = item.body
            time.text = item.getTimeString()
            subpath = "m/\(item.key!)"
            
        case TYPE_EM:
            body.text = item.body
            time.text = item.getTimeString()
            subpath = "em"
            break
            
        default:
            break
        }
        
        DispatchQueue.main.async {
            self.notificationContainer.layer.cornerRadius = 15
            self.notificationContainer.clipsToBounds = true
        }
    }
    

    @IBAction func closeButtonTapped(_ sender: UIButton) {
        if subpath != nil && subpath.count > 0 {
            delegate.closeNotification(subpath: subpath, row: rowNumber)
        }
    }
    
    
}
