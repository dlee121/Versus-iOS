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
    
    var profileImageVersion : Int
    
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
        
        profileImageVersion = 0
    }
    
    
    //for initializing from compact source for Search and Posts history
    init(compactSource : VSPostsListCompactModel_hits_hits_item__source, id : String){
        
        blackcount = compactSource.bc!
        blackname = compactSource.bn!
        author = compactSource.a!
        question = compactSource.q!
        time = compactSource.t!
        redcount = compactSource.rc!
        redname = compactSource.rn!
        
        category = 0
        post_id = id
        redimg = 0
        blackimg = 0
        pt = 0
        ps = 0
        
        profileImageVersion = 0
        
    }
    
    init (itemSource : VSPostModel__source, id : String){
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
        
        profileImageVersion = 0
    }
    
    
    func setProfileImageVersion(piv : Int){
        profileImageVersion = piv
    }
    
}
