//
//  VSComment.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/24/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import Foundation

class UserAction {
    var id : String //username+postID
    var votedSide : String //"none", "RED", "BLK"
    var actionRecord : [String : String] //Key = comment_id, Value = String value, N for novote, U for upvote, D for downvote.
    
    init(itemSource : VSRecordPutModel, idIn : String){
        id = idIn
        votedSide = itemSource.v!
        
        actionRecord = [String : String]()
        
        for dId in itemSource.d! {
            actionRecord[dId] = "D"
        }
        
        for nId in itemSource.n! {
            actionRecord[nId] = "N"
        }
        
        for uId in itemSource.u! {
            actionRecord[uId] = "U"
        }
    }
    
    init(idIn : String){
        id = idIn
        votedSide = "none"
        actionRecord = [String : String]()
    }
    
    
    
    
    
}
