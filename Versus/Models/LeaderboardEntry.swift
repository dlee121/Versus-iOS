//
//  LeaderboardEntry.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/13/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import Foundation

class LeaderboardEntry {
    
    var username : String
    var b : Int
    var s : Int
    var g : Int
    var influence : Int
    var pi : Int
    
    init(itemSource : VSLeaderboardModel_hits_hits_item__source){
        username = itemSource.cs!
        b = itemSource.b!.intValue
        g = itemSource.g!.intValue
        influence = itemSource._in!.intValue
        pi = itemSource.pi!.intValue
        s = itemSource.s!.intValue
    }
    
}
