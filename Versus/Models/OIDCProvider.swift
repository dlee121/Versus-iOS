//
//  OIDCProvider.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/2/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import Foundation
import FirebaseAuth

class OIDCProvider: NSObject, AWSIdentityProviderManager {
    var tokenIn : NSString!
    
    init(input : NSString) {
        tokenIn = input
    }
    
    func logins() -> AWSTask<NSDictionary> {
        print("logins() called")
        
        return AWSTask(result:["securetoken.google.com/bcd-versus":UserDefaults.standard.object(forKey: "KEY_TOKEN") as! NSString])
    }
    
    
}
