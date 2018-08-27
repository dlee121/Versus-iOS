//
//  ViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 6/27/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import Firebase
import PopupDialog

class ViewController: UIViewController {
    @IBOutlet weak var usernameIn: UITextField!
    @IBOutlet weak var passwordIn: UITextField!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    var handle: AuthStateDidChangeListenerHandle!
    var unauthClient : VSVersusAPIClient!
    var emailSetUpButtonLock = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "eye.png"), for: .normal)
        //button.imageEdgeInsets = UIEdgeInsetsMake(0, -16, 0, 0)
        button.frame = CGRect(x: CGFloat(passwordIn.frame.size.width - 25), y: CGFloat(5), width: CGFloat(25), height: CGFloat(25))
        button.addTarget(self, action: #selector(self.pwtoggle), for: .touchUpInside)
        passwordIn.rightView = button
        passwordIn.rightViewMode = .always
    }
    
    override func viewWillAppear(_ animated: Bool){
        super.viewWillAppear(animated)
        emailSetUpButtonLock = false
        
        //remove session data, log out firebase user, then segue back to start screen
        UserDefaults.standard.removeObject(forKey: "KEY_BDAY")
        UserDefaults.standard.removeObject(forKey: "KEY_EMAIL")
        UserDefaults.standard.removeObject(forKey: "KEY_USERNAME")
        UserDefaults.standard.removeObject(forKey: "KEY_PI")
        UserDefaults.standard.removeObject(forKey: "KEY_IS_NATIVE")
        try! Auth.auth().signOut()
        
        let credentialProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: "us-east-1:88614505-c8df-4dce-abd8-79a0543852ff")
        credentialProvider.clearCredentials()
        let configurationAuth = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialProvider)
        //unauth config is stored in individual client instances and not in default, which is reserved for auth config
        unauthClient = VSVersusAPIClient(configuration: configurationAuth!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func logInButtonTapped(_ sender: UIButton) {
        //log in user with Firebase
        
        if let username = usernameIn.text {
            if let pw = passwordIn.text{
                if username.count == 0{
                    showToast(message: "Please enter your username", length: 26)
                }
                else if pw.count == 0{
                    showToast(message: "Please enter your password", length: 26)
                }
                else{
                    var loginEmail = username+"@versusbcd.com"
                    unauthClient.getemailGet(a: "gem", b: username).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                        if task.error != nil {
                            DispatchQueue.main.async {
                                print(task.error!)
                            }
                        }
                        else {
                            if let emailModel = task.result {
                                if emailModel.em != "0" {
                                    loginEmail = emailModel.em!
                                }
                                
                                Auth.auth().signIn(withEmail: loginEmail, password: pw) { (result, error) in
                                    // ...
                                    if let user = result?.user {
                                        
                                        user.getIDTokenForcingRefresh(true){ (idToken, error) in
                                            
                                            let oidcProvider = OIDCProvider(input: idToken! as NSString)
                                            let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1, identityPoolId:"us-east-1:88614505-c8df-4dce-abd8-79a0543852ff", identityProviderManager: oidcProvider)
                                            credentialsProvider.clearCredentials()
                                            let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider:credentialsProvider)
                                            //login session configuration is stored in the default
                                            AWSServiceManager.default().defaultServiceConfiguration = configuration
                                            
                                            VSVersusAPIClient.default().userGet(a: "getu", b: username.lowercased()).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                                                if task.error != nil {
                                                    DispatchQueue.main.async {
                                                        print(task.error!)
                                                    }
                                                }
                                                else {
                                                    let userGetModel = task.result
                                                    //create user session and segue to MainContainer
                                                    UserDefaults.standard.set(userGetModel?.bd, forKey: "KEY_BDAY")
                                                    UserDefaults.standard.set(userGetModel?.em, forKey: "KEY_EMAIL")
                                                    UserDefaults.standard.set(userGetModel?.cs, forKey: "KEY_USERNAME")
                                                    UserDefaults.standard.set(userGetModel?.pi?.intValue, forKey: "KEY_PI")
                                                    UserDefaults.standard.set(true, forKey: "KEY_IS_NATIVE")
                                                    
                                                    DispatchQueue.main.async {
                                                        self.performSegue(withIdentifier: "logInToMain", sender: self)
                                                    }
                                                }
                                                return nil
                                            }
                                            
                                            
                                            
                                            
                                        }
                                        
                                        
                                    }
                                    else{
                                        self.showToast(message: "incorrect username or password", length: 30)
                                    }
                                }
                                
                                
                            }
                        }
                        return nil
                    }
                    
                }
            }
            else{
                showToast(message: "Please enter your password", length: 26)
            }
        }
        else {
            showToast(message: "Please enter your username", length: 26)
            
        }
        
        
    }
    
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        //sign up user with Firebase
        
        //try? Auth.auth().signOut()
        
        performSegue(withIdentifier: "goToBirthday", sender: self)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //dismiss keyboard when the view is tapped on
        usernameIn.resignFirstResponder()
        passwordIn.resignFirstResponder()
    }
    
    @objc
    func pwtoggle(_ sender: Any) {
        passwordIn.isSecureTextEntry = !passwordIn.isSecureTextEntry
        if let existingText = passwordIn.text, passwordIn.isSecureTextEntry {
            /* When toggling to secure text, all text will be purged if the user
             * continues typing unless we intervene. This is prevented by first
             * deleting the existing text and then recovering the original text. */
            passwordIn.deleteBackward()
            
            if let textRange = passwordIn.textRange(from: passwordIn.beginningOfDocument, to: passwordIn.endOfDocument) {
                passwordIn.replace(textRange, withText: existingText)
            }
        }
        else if let textRange = passwordIn.textRange(from: passwordIn.beginningOfDocument, to: passwordIn.endOfDocument) {
            //we still do this to get rid of extra spacing that happens when toggling secure text
            passwordIn.replace(textRange, withText: passwordIn.text!)
        }
        
    }
    
    
    @IBAction func passwordRecoveryTapped(_ sender: UIButton) {
        showCustomDialog()
    }
    
    func showCustomDialog(animated: Bool = true) {
        
        // Create a custom view controller
        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let emailSetupVC : EmailSetupVC = storyboard.instantiateViewController(withIdentifier: "emailSetupVC") as! EmailSetupVC
        // Create the dialog
        let popup = PopupDialog(viewController: emailSetupVC,
                                buttonAlignment: .horizontal,
                                transitionStyle: .bounceDown,
                                tapGestureDismissal: true,
                                panGestureDismissal: false)
        
        // Create first button
        let buttonOne = CancelButton(title: "CANCEL", height: 30) {
            print("cancel")
        }
        
        // Create second button
        let buttonTwo = DefaultButton(title: "OK", height: 30, dismissOnTap: false) {
            if !self.emailSetUpButtonLock {
                self.emailSetUpButtonLock = true
                let user = Auth.auth().currentUser
                var userEmail: String!
                let emailInput = emailSetupVC.textField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                
                
                if self.isEmail(email: emailInput){
                    if emailSetupVC.emPwIn.text?.count == 0 {
                        //pop a toast "Please enter your username."
                        self.showToast(message: "Please enter your username.", length: 27)
                        self.emailSetUpButtonLock = false
                    }
                    else {
                        
                    }
                }
                else {
                    //pop a toast "please enter a valid email"
                    self.showToast(message: "please enter a valid email", length: 26)
                    self.emailSetUpButtonLock = false
                }
                
                
            }
            
        }
        
        // Add buttons to dialog
        popup.addButtons([buttonOne, buttonTwo])
        
        // Present dialog
        present(popup, animated: animated, completion: nil)
    }
    
    func isEmail(email : String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return email.count > 0 && emailTest.evaluate(with: email)
    }
    
    
}

