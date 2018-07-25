//
//  VSComment.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/24/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import Foundation

class PostInfo {
    var r, b, q, a : String?
    var rc, bc : Int?
    
    init(itemSource : VSPostInfoModel){
        r = itemSource.rn
        b = itemSource.bn
    }
    
    init(itemSource : VSPostInfoMultiModel_docs_item__source){
        r = itemSource.rn
        b = itemSource.bn
    }
    
    init(itemSource : VSPostQModel){
        q = itemSource.q
        a = itemSource.a
        rc = itemSource.rc?.intValue
        bc = itemSource.bc?.intValue
    }
    
    init(itemSource : VSPostQMultiModel_docs_item__source){
        q = itemSource.q
        a = itemSource.a
        rc = itemSource.rc?.intValue
        bc = itemSource.bc?.intValue
    }
    
    
    
}
