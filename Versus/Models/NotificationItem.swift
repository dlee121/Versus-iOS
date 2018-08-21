//
//  NotificationItem.swift
//  Versus
//
//  Created by Dongkeun Lee on 8/17/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import Foundation

class NotificationItem: Comparable {
    
    let TYPE_U = 0 //new comment upvote notification
    let TYPE_C = 1 //new comment reply notification
    let TYPE_V = 2 //new post vote notification
    let TYPE_R = 3 //new post root comment notification
    let TYPE_F = 4 //new follower notification
    let TYPE_M = 5 //new medal notification
    let TYPE_EM = 6 //for password reset email setup notification
    
    var body, payload, medalType, identifier, key : String?
    var type, timestamp : Int?
    
    init(body : String, type : Int, payload : String, timestamp : Int, key : String){
        self.body = body
        self.type = type
        self.payload = payload
        self.timestamp = timestamp
        self.key = key
    }
    
    init (body : String, type : Int, timestamp: Int) {
        self.body = body
        self.type = type
        self.timestamp = timestamp
        self.key = ""
    }
    
    init (body : String, type : Int, timestamp : Int, key : String) {
        self.body = body
        self.type = type
        self.timestamp = timestamp
        self.key = key
    }
    
    init (body : String, type : Int, payload : String, timestamp : Int, medalType : String, key : String) {
        self.body = body
        self.type = type
        self.payload = payload
        self.timestamp = timestamp
        self.medalType = medalType
        self.key = key
    }
    
    
    func getTimeString() -> String {
        var timeFormat = 0
        var timediff = Int(NSDate().timeIntervalSince1970 - Double(timestamp!))
        
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
        
        if timediff == 0 {
            return "Just now"
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
    
    static func < (lhs: NotificationItem, rhs: NotificationItem) -> Bool {
        return lhs.timestamp! < rhs.timestamp!
    }
    
    static func == (lhs: NotificationItem, rhs: NotificationItem) -> Bool {
        return lhs.timestamp! == rhs.timestamp!
    }
    
}




