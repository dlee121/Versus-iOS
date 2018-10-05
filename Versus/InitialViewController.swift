//
//  InitialViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/4/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import FirebaseAuth
import Appodeal

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
                    
                    //retrieve "bd" from UserDefaults, get gdpr value
                    if self.isInEU() {
                        print("in EU")
                        if let gdprConsentValue = UserDefaults.standard.string(forKey: "KEY_BDAY") {
                            if gdprConsentValue == "gdpr1" {
                                Appodeal.initialize(withApiKey: "819054921bcb6cc21aa0e7a19f852d182975592b907d0ad3", types: .nativeAd, hasConsent: true)
                            }
                            else {
                                Appodeal.initialize(withApiKey: "819054921bcb6cc21aa0e7a19f852d182975592b907d0ad3", types: .nativeAd, hasConsent: false)
                            }
                        }
                        else {
                            Appodeal.initialize(withApiKey: "819054921bcb6cc21aa0e7a19f852d182975592b907d0ad3", types: .nativeAd, hasConsent: false)
                        }
                    }
                    else {
                        print("not in EU")
                        Appodeal.initialize(withApiKey: "819054921bcb6cc21aa0e7a19f852d182975592b907d0ad3", types: .nativeAd, hasConsent: true)
                    }
                    
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

    func isInEU() -> Bool {
        
        if let regionCode = Locale.current.regionCode {
            switch regionCode {
            case "AT":
                return true
            case "BE":
                return true
            case "BG":
                return true
            case "HR":
                return true
            case "CY":
                return true
            case "CZ":
                return true
            case "DK":
                return true
            case "EE":
                return true
            case "FI":
                return true
            case "FR":
                return true
            case "DE":
                return true
            case "GR":
                return true
            case "HU":
                return true
            case "IE":
                return true
            case "IT":
                return true
            case "LV":
                return true
            case "LT":
                return true
            case "LU":
                return true
            case "MT":
                return true
            case "NL":
                return true
            case "PL":
                return true
            case "PT":
                return true
            case "RO":
                return true
            case "SK":
                return true
            case "SI":
                return true
            case "ES":
                return true
            case "SE":
                return true
            case "GB":
                return true
            default:
                return false
            }
        }
        else {
            return false
        }
    }
    
    
}
