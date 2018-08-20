//
//  VSComment.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/24/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import Foundation

class MedalUpdateRequest {
    var p, t : Int //points increment and time value
    var c : String //sanitized comment content
    
    
    init(p : Int, t : Int, c : String){
        self.p = p
        self.t = t
        self.c = c
    }
    
    
    
}
