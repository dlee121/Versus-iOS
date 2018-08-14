//
//  VSComment.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/24/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import Foundation

class VSComment {
    
    var parent_id, post_id, time, comment_id, author, content, root : String
    var topmedal, upvotes, downvotes, comment_influence : Int
    var uservote, currentMedal, child_count : Int?
    var nestedLevel : CGFloat?
    
    let NOVOTE = 0
    let UPVOTE = 1
    let DOWNVOTE = 2
    
    var isNew, isHighlighted : Bool?
    var postAuthor, question : String?
    var rc, bc : Int?
    var redName, blueName : String?
    
    init(itemSource : VSCommentsListModel_hits_hits_item__source, id : String){
        parent_id = itemSource.pr!
        post_id = itemSource.pt!
        time = itemSource.t!
        comment_id = id
        author = itemSource.a!
        content = itemSource.ct!
        root = itemSource.r!
        topmedal = itemSource.m!.intValue
        upvotes = itemSource.u!.intValue
        downvotes = itemSource.d!.intValue
        comment_influence = itemSource.ci!.intValue
        
    }
    
    init(itemSource : VSCGCModel_responses_item_hits_hits_item__source, id : String){
        parent_id = itemSource.pr!
        post_id = itemSource.pt!
        time = itemSource.t!
        comment_id = id
        author = itemSource.a!
        content = itemSource.ct!
        root = itemSource.r!
        topmedal = itemSource.m!.intValue
        upvotes = itemSource.u!.intValue
        downvotes = itemSource.d!.intValue
        comment_influence = itemSource.ci!.intValue
        
    }
    
    init(itemSource : VSCommentModel__source, id : String){
        parent_id = itemSource.pr!
        post_id = itemSource.pt!
        time = itemSource.t!
        comment_id = id
        author = itemSource.a!
        content = itemSource.ct!
        root = itemSource.r!
        topmedal = itemSource.m!.intValue
        upvotes = itemSource.u!.intValue
        downvotes = itemSource.d!.intValue
        comment_influence = itemSource.ci!.intValue
    }
    
    init(){ //to initiate this object as a placeholder for the post object, used for Post Page's Root Page
        parent_id = "0"
        post_id = "0"
        time = "0"
        comment_id = "0"
        author = "0"
        content = "0"
        root = "0"
        topmedal = 0
        upvotes = 0
        downvotes = 0
        comment_influence = 0
    }
    
    init(username : String, parentID: String, postID: String, newContent : String, rootID : String){
        parent_id = parentID
        post_id = postID
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        time = formatter.string(from: Date())
        
        comment_id = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        author = username
        content = newContent
        root = rootID
        topmedal = 0
        upvotes = 0
        downvotes = 0
        comment_influence = 0
        
        uservote = NOVOTE
        currentMedal = 0
        child_count = 0
    }
    
    func setAQRCBC(source : VSPostQMultiModel_docs_item__source){
        postAuthor = source.a
        question = source.q
        rc = source.rc?.intValue
        bc = source.bc?.intValue
        
    }
    
    func getPutModel() -> VSCommentPutModel {
        var putModel = VSCommentPutModel()
        
        putModel!.a = author
        putModel!.ci = NSNumber(value: comment_influence)
        putModel!.ct = content
        putModel!.d = NSNumber(value: downvotes)
        putModel!.m = NSNumber(value: topmedal)
        putModel!.pr = parent_id
        putModel!.pt = post_id
        putModel!.r = root
        putModel!.t = time
        putModel!.u = NSNumber(value: upvotes)
        
        return putModel!
        
        
    }
    
    
    
}
