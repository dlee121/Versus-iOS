//
//  PasswordViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 6/29/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import Firebase

class PasswordViewController: UIViewController {

    var username : String!
    var birthday : Date!
    @IBOutlet weak var debugLabel: UILabel!
    @IBOutlet weak var passwordIn: UITextField!
    var confirmedPW : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
        let formatter = DateFormatter()
        formatter.dateFormat = "M-d-yyyy"
        let myStringafd = formatter.string(from: birthday!)
        */
        
        debugLabel.text = ""
        

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func backTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "backToUsername", sender: self)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == "backToUsername"{
                guard let usernameVC = segue.destination as? UsernameViewController else {return}
                usernameVC.birthday = birthday
                print(username)
                usernameVC.confirmedInput = username
            }
        }
    }
 
    
    @IBAction func textChangeListener(_ sender: UITextField) {
        confirmedPW = nil
        if let input = passwordIn.text{
            if input.count > 0{
                if input.count >= 6{
                    if input.prefix(1) == " "{
                        debugLabel.text = "Password cannot start with blank space"
                        debugLabel.textColor = UIColor(named: "noticeRed")
                    }
                    else if input.suffix(1) == " "{
                        debugLabel.text = "Password cannot end with blank space"
                        debugLabel.textColor = UIColor(named: "noticeRed")
                    }
                    else{
                        passwordStrengthCheck(pw: input)
                        confirmedPW = input
                    }
                }
                else{
                    debugLabel.text = "Must be at least 6 characters"
                    debugLabel.textColor = UIColor(named: "noticeRed")
                }
            }
            else{
                debugLabel.text = ""
            }
        }
    }
    
    func passwordStrengthCheck(pw: String) {
        var strength = 0
        
        if(pw.count >= 4){
            strength += 1
        }
        if(pw.count >= 6){
            strength += 1
        }
        if(pw.lowercased() != pw){
            strength += 1
        }
        var digitCount = 0
        for i in 0...pw.count-1 {
            if "0"..."9" ~= String(pw[pw.index(pw.startIndex, offsetBy: i)]) {
                digitCount += 1
            }
        }
        if(1...pw.count ~= digitCount){
            strength += 1
        }
        
        switch (strength){
            case 0:
                debugLabel.textColor = UIColor(named: "noticeRed")
                debugLabel.text = "Password strength: weak"
            case 1:
                debugLabel.textColor = UIColor(named: "noticeRed")
                debugLabel.text = "Password strength: weak"
            case 2:
                debugLabel.text = "Password strength: medium"
                debugLabel.textColor = UIColor(named: "noticeYellow")
            case 3:
                debugLabel.text = "Password strength: good"
                debugLabel.textColor = UIColor(named: "noticeGreen")
            case 4:
                debugLabel.text = "Password strength: strong"
                debugLabel.textColor = UIColor(named: "noticeGreen")
            default:
                debugLabel.text = "Password strength: medium"
                debugLabel.textColor = UIColor(named: "noticeYellow")
        }
    }
    
    
    @IBAction func nextTapped(_ sender: Any) {
        //sign up the user using firebase
        if birthday != nil && username != nil && confirmedPW != nil {
            Auth.auth().createUser(withEmail: username+"@versusbcd.com", password: confirmedPW) { (authResult, error) in
                // ...
                if let user = authResult?.user {
                    print("signed up as " + user.email!)
                    user.getIDTokenForcingRefresh(true){ (idToken, error) in
                        
                        let oidcProvider = OIDCProvider(input: idToken! as NSString)
                        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1, identityPoolId:"us-east-1:88614505-c8df-4dce-abd8-79a0543852ff", identityProviderManager: oidcProvider)
                        credentialsProvider.clearCredentials()
                        let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider:credentialsProvider)
                        //login session configuration is stored in the default
                        AWSServiceManager.default().defaultServiceConfiguration = configuration
                        
                        
                        
                        
                        //populate a UserPutModel and put it into ElasticSearch using api client
                        let userPutModel = VSUserPutModel()
                        userPutModel?.ai = "0" //AuthID for fb/google signup, hence the default value of "0" for native signup
                        userPutModel?.b = 0 //initial bronze medal count
                        
                        let formatter = DateFormatter()
                        formatter.dateFormat = "M-d-yyyy"
                        userPutModel?.bd = formatter.string(from: self.birthday!) //birthday
                        
                        userPutModel?.cs = self.username //case-sensitive username for display purposes, since user is stored with id = username.lowercased()
                        userPutModel?.em = "0" //default value for email
                        userPutModel?.g = 0 //initial gold medal count
                        userPutModel?._in = 0 //initial user influence
                        userPutModel?.pi = 0 //initial value for profile image version
                        userPutModel?.s = 0 //initial silver medal count
                        
                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                        userPutModel?.t = formatter.string(from: Date()) //signup timestamp
                        
                        VSVersusAPIClient.default().userputPost(body: userPutModel!, c: self.username.lowercased(), a: "put", b: "user").continueWith(block:) {(task: AWSTask) -> AnyObject? in
                            if task.error != nil{
                                DispatchQueue.main.async {
                                    self.showToast(message: "Something went wrong. Please try again.", length: 39)
                                }
                            }
                            else { //successfully created user
                                //send new user notification (instructions for them to set up password-reset email, which is
                                /*
                                 String userNotificationPath = getUsernameHash(newUser.getUsername()) + "/" + newUser.getUsername() + "/n/em/";
                                 FirebaseDatabase.getInstance().getReference().child(userNotificationPath).setValue(true);
                                 */
                                
                                
                                
                                
                                
                                
                                //create user session and segue to MainContainer
                                
                                
                                DispatchQueue.main.async {
                                    self.performSegue(withIdentifier: "signUpToMain", sender: self)
                                }
                            }
                            
                            return nil
                        }
                        
                    }
                    
                }
                else{
                    self.showToast(message: "Something went wrong, please try again.", length: 39)
                }
            }
        }
        else {
            showToast(message: "Something went wrong, please try again.", length: 39)
        }
        
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
