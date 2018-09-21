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
        
        if let tokenDateObject = (UserDefaults.standard.object(forKey: "KEY_Token") as? Date) {
            if tokenDateObject.timeIntervalSinceNow > 900 {
                return AWSTask(result:["securetoken.google.com/bcd-versus":self.tokenIn])
            }
        }
        
        //refresh token, set the new token as tokenIn, and then return it
        let group = DispatchGroup()
        group.enter()
        Auth.auth().currentUser!.getIDTokenForcingRefresh(true){ (idToken, error) in
            self.tokenIn = idToken! as NSString
            group.leave()
        }
        
        group.wait()
        
        return AWSTask(result:["securetoken.google.com/bcd-versus":self.tokenIn])
    }
    
    
}
