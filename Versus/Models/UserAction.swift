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
    var changed : Bool
    
    
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
        changed = false
    }
    
    init(idIn : String){
        id = idIn
        votedSide = "none"
        actionRecord = [String : String]()
        changed = false
    }
    
    func getRecordPutModel() -> VSRecordPutModel {
        var recordPutModel = VSRecordPutModel()!
        
        recordPutModel.n = [String]()
        recordPutModel.d = [String]()
        recordPutModel.u = [String]()
        
        for recordItem in actionRecord {
            switch recordItem.value {
            case "N":
                recordPutModel.n!.append(recordItem.key)
            case "D":
                recordPutModel.d!.append(recordItem.key)
            case "U":
                recordPutModel.u!.append(recordItem.key)
            default:
                actionRecord.removeValue(forKey: recordItem.key)
            }
        }
        
        recordPutModel.v = votedSide
        
        return recordPutModel
        
    }
    
    
    
    
    
}
