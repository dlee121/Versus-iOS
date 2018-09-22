//
//  InitialViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/4/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class InitialViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //the token verification and refresh here does not conflict with token verification in AppDelegate, since this one is called for fresh launch and the AppDelegate one is called for relaunch
        if let user = Auth.auth().currentUser {
            if UserDefaults.standard.string(forKey: "KEY_USERNAME") != nil {
                //get user token, set up cognito auth credentials, then segue to MainContainer
                user.getIDTokenForcingRefresh(true){ (idToken, error) in
                    //store the fresh token in UserDefaults
                    UserDefaults.standard.set(idToken, forKey: "KEY_TOKEN")
                    
                    let oidcProvider = OIDCProvider(input: idToken! as NSString)
                    let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1, identityPoolId:"us-east-1:88614505-c8df-4dce-abd8-79a0543852ff", identityProviderManager: oidcProvider)
                    credentialsProvider.clearCredentials()
                    let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider:credentialsProvider)
                    //login session configuration is stored in the default
                    AWSServiceManager.default().defaultServiceConfiguration = configuration
                    
                    AWSServiceManager.default().defaultServiceConfiguration.credentialsProvider.invalidateCachedTemporaryCredentials()
                    AWSServiceManager.default().defaultServiceConfiguration.credentialsProvider.credentials().continueOnSuccessWith { (task:AWSTask<AWSCredentials>) -> Any? in
                        
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "initialToMain", sender: self)
                        }
                        
                    }
                }
            }
            else {
                performSegue(withIdentifier: "initialToStart", sender: self)
            }
        }
        else{
            //user not logged in, segue to Start Screen
            performSegue(withIdentifier: "initialToStart", sender: self)
        }
 
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
