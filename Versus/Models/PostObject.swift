//
//  PostObject.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/5/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import Foundation

class PostObject {
    
    var question : String
    var author : String
    var time : String
    var redname : String
    var redcount : NSNumber
    var blackname : String
    var blackcount : NSNumber
    var category : NSNumber
    var post_id : String
    var redimg : NSNumber
    var blackimg : NSNumber
    var pt : NSNumber
    var ps : NSNumber
    
    init(itemSource : VSPostsListModel_hits_hits_item__source, id : String){
        question = itemSource.q!
        author = itemSource.a!
        time = itemSource.t!
        redname = itemSource.rn!
        redcount = itemSource.rc!
        blackname = itemSource.bn!
        blackcount = itemSource.bc!
        category = itemSource.c!
        post_id = id
        redimg = itemSource.ri!
        blackimg = itemSource.bi!
        pt = itemSource.pt!
        ps = itemSource.ps!
        
    }
    
}
