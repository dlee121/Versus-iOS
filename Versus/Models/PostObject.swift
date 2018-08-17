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
    
    init (q : String, rn : String, bn : String, a : String, c : NSNumber, ri : NSNumber, bi : NSNumber) {
        question = q
        author = a
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        time = formatter.string(from: Date())
        
        redname = rn
        redcount = 0
        blackname = bn
        blackcount = 0
        category = c
        post_id = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        
        redimg = ri
        blackimg = bi
        
        pt = NSNumber(value: Int(((NSDate().timeIntervalSince1970/60)/60)/24))
        ps = 0
        
        profileImageVersion = 0
    }
    
    func getPostPutModel() -> VSPostPutModel {
        var putModel = VSPostPutModel()
        putModel?.q = question
        putModel?.a = author
        putModel?.t = time
        putModel?.rn = redname
        putModel?.rc = redcount
        putModel?.bn = blackname
        putModel?.bc = blackcount
        putModel?.c = category
        putModel?.ri = redimg
        putModel?.bi = blackimg
        putModel?.pt = pt
        putModel?.ps = ps
        
        return putModel!
    }
    
    
    func setProfileImageVersion(piv : Int){
        profileImageVersion = piv
    }
    
}
