//
//  VSComment.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/24/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import Foundation

class VSCNode {
    var headSibling, tailSibling, firstChild, parent : VSCNode? //holds comment_id of headSibling, tailSibling, firstChild, and parent node
    var nodeContent : VSComment
    
    init(comment : VSComment){
        nodeContent = comment
    }
    
    func votedUpdate(upvotes: Int, downvotes: Int){
        nodeContent.upvotes = upvotes
        nodeContent.downvotes = downvotes
    }
    
    
    
}
