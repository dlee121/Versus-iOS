//
//  SignUpViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 9/16/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import JWTDecode

class SignUpViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SignUpDelegator {
    
    var array = {"SignUp"}
    var authID : String?
    var authCredential : AuthCredential?
    var screenHeight : CGFloat!
    
    @IBOutlet weak var tableView: UITableView!
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "signUpCell", for: indexPath) as! SignUpTableViewCell
        cell.setCell(isNative: (authID == nil), delegator: self)
        return cell
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        
        screenHeight = UIScreen.main.bounds.height
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillHide,
                                               object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        NotificationCenter.default.removeObserver(self)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        tableView.isScrollEnabled = true
        
        if authID == nil || screenHeight < 666 {
            let userInfo: NSDictionary = notification.userInfo! as NSDictionary
            let keyboardInfo = userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue
            let keyboardSize = keyboardInfo.cgRectValue.size
            if keyboardSize.height > tableView.contentInset.bottom {
                let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
                tableView.contentInset = contentInsets
                tableView.scrollIndicatorInsets = contentInsets
                tableView.scrollToRow(at: IndexPath(item: 0, section: 0), at: UITableViewScrollPosition.bottom, animated: true)
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        tableView.isScrollEnabled = false
        
        if authID == nil || screenHeight < 666 {
            tableView.contentInset = .zero
            tableView.scrollIndicatorInsets = .zero
        }
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func signUpButtonTapped(username: String, pw: String?) {
        
        if authID == nil {
            //native signup
            if username != nil && pw != nil {
                let password = pw! //just so I don't fuck around and end up with "Optional("pw")"
                
                Auth.auth().createUser(withEmail: username+"@versusbcd.com", password: password) { (authResult, error) in
                    // ...
                    if let user = authResult?.user {
                        
                        user.getIDTokenForcingRefresh(true){ (idToken, error) in
                            
                            do {
                                let jwt = try decode(jwt: idToken!)
                                UserDefaults.standard.set(jwt.expiresAt, forKey: "KEY_Token")
                            }
                            catch {
                                UserDefaults.standard.set(Date(), forKey: "KEY_Token")
                            }
                            
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
                            
                            userPutModel?.bd = "0" //birthday, a legacy placeholder in this case
                            
                            userPutModel?.cs = username //case-sensitive username for display purposes, since user is stored with id = username.lowercased()
                            userPutModel?.em = "0" //default value for email
                            userPutModel?.g = 0 //initial gold medal count
                            userPutModel?._in = 0 //initial user influence
                            userPutModel?.pi = 0 //initial value for profile image version
                            userPutModel?.s = 0 //initial silver medal count
                            
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                            userPutModel?.t = formatter.string(from: Date()) //signup timestamp
                            
                            VSVersusAPIClient.default().userputPost(body: userPutModel!, c: username.lowercased(), a: "put", b: "user").continueWith(block:) {(task: AWSTask) -> AnyObject? in
                                if task.error != nil{
                                    DispatchQueue.main.async {
                                        self.showToast(message: "Something went wrong. Please try again.", length: 39)
                                    }
                                }
                                else { //successfully created user
                                    //send new user notification about account recovery setup
                                    var usernameHash : Int32
                                    if(username.count < 5){
                                        usernameHash = username.hashCode()
                                    }
                                    else{
                                        var hashIn = ""
                                        
                                        hashIn.append(username[0])
                                        hashIn.append(username[username.count-2])
                                        hashIn.append(username[1])
                                        hashIn.append(username[username.count-1])
                                        
                                        usernameHash = hashIn.hashCode()
                                    }
                                    
                                    let userNotificationPath = "\(usernameHash)/" + username + "/n/em/"
                                    Database.database().reference().child(userNotificationPath).setValue(true)
                                    
                                    //create user session and segue to MainContainer
                                    UserDefaults.standard.set("0", forKey: "KEY_BDAY")
                                    UserDefaults.standard.set("0", forKey: "KEY_EMAIL")
                                    UserDefaults.standard.set(username, forKey: "KEY_USERNAME")
                                    UserDefaults.standard.set(0, forKey: "KEY_PI")
                                    UserDefaults.standard.set(true, forKey: "KEY_IS_NATIVE")
                                    
                                    
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
                showToast(message: "Please check your network.", length: 26)
            }
            
        }
        else {
            //fb or google signup
            if username != nil && authCredential != nil {
                Auth.auth().signInAndRetrieveData(with: self.authCredential!) { (authResult, error) in
                    if let error = error {
                        // ...
                        return
                    }
                    
                    if let user = authResult?.user {
                        user.getIDTokenForcingRefresh(true){ (idToken, error) in
                            
                            do {
                                let jwt = try decode(jwt: idToken!)
                                UserDefaults.standard.set(jwt.expiresAt, forKey: "KEY_Token")
                            }
                            catch {
                                UserDefaults.standard.set(Date(), forKey: "KEY_Token")
                            }
                            
                            let oidcProvider = OIDCProvider(input: idToken! as NSString)
                            let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1, identityPoolId:"us-east-1:88614505-c8df-4dce-abd8-79a0543852ff", identityProviderManager: oidcProvider)
                            credentialsProvider.clearCredentials()
                            let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider:credentialsProvider)
                            //login session configuration is stored in the default
                            AWSServiceManager.default().defaultServiceConfiguration = configuration
                            
                            //populate a UserPutModel and put it into ElasticSearch using api client
                            let userPutModel = VSUserPutModel()
                            userPutModel?.ai = self.authID! //AuthID for fb/google signup
                            userPutModel?.b = 0 //initial bronze medal count
                            
                            userPutModel?.bd = "0" //birthday, a legacy placeholder in this case
                            
                            userPutModel?.cs = username //case-sensitive username for display purposes, since user is stored with id = username.lowercased()
                            userPutModel?.em = "0" //default value for email
                            userPutModel?.g = 0 //initial gold medal count
                            userPutModel?._in = 0 //initial user influence
                            userPutModel?.pi = 0 //initial value for profile image version
                            userPutModel?.s = 0 //initial silver medal count
                            
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                            userPutModel?.t = formatter.string(from: Date()) //signup timestamp
                            
                            VSVersusAPIClient.default().userputPost(body: userPutModel!, c: username.lowercased(), a: "put", b: "user").continueWith(block:) {(task: AWSTask) -> AnyObject? in
                                if task.error != nil{
                                    DispatchQueue.main.async {
                                        self.showToast(message: "Something went wrong. Please try again.", length: 39)
                                    }
                                }
                                else { //successfully created user
                                    
                                    //create user session and segue to MainContainer
                                    UserDefaults.standard.set("0", forKey: "KEY_BDAY")
                                    UserDefaults.standard.set("0", forKey: "KEY_EMAIL")
                                    UserDefaults.standard.set(username, forKey: "KEY_USERNAME")
                                    UserDefaults.standard.set(0, forKey: "KEY_PI")
                                    UserDefaults.standard.set(false, forKey: "KEY_IS_NATIVE")
                                    
                                    
                                    DispatchQueue.main.async {
                                        self.performSegue(withIdentifier: "signUpToMain", sender: self)
                                    }
                                }
                                
                                return nil
                            }
                            
                        }
                        
                    }
                }
                
                
            }
            else {
                showToast(message: "Please check your network.", length: 26)
            }
        }
        
        
    }
    
    func showSUVCToast(text : String) {
        showToast(message: text, length: text.count)
    }
    

}

protocol SignUpDelegator {
    func signUpButtonTapped(username : String, pw : String?)
    func showSUVCToast(text : String)
}




