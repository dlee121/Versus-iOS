//
//  UsernameViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 6/29/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class UsernameViewController: UIViewController {
    
    var birthday: Date!
    @IBOutlet weak var debugLabel: UILabel!
    
    var credentialProvider : AWSCognitoCredentialsProvider!
    var configurationAuth : AWSServiceConfiguration!
    var client : VSVersusAPIClient!
    var usernameVersion = 0
    var confirmedInput : String! //username input that is confirmed to be available. Use this for signup
    var confirmed : Bool = false
    
    @IBOutlet weak var usernameIn: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        credentialProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: "us-east-1:88614505-c8df-4dce-abd8-79a0543852ff")
        credentialProvider.clearCredentials()
        configurationAuth = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialProvider)
        client = VSVersusAPIClient(configuration: configurationAuth)
        
        usernameVersion = 0
        if confirmedInput != nil{
            usernameIn.text = confirmedInput
            usernameVersion += 1
            let thisVersion = usernameVersion
            let input = confirmedInput
            self.debugLabel.text = "Checking username..."
            client.userHead(a: "uc", b: usernameIn.text?.lowercased()).continueWith(block:) {(task: AWSTask) -> Empty? in
                if task.error != nil{
                    DispatchQueue.main.async {
                        if(thisVersion == self.usernameVersion){
                            self.confirmed = true
                            self.debugLabel.text = "Username available"
                            self.confirmedInput = input!
                        }
                    }
                }
                else{
                    DispatchQueue.main.async {
                        if(thisVersion == self.usernameVersion){
                            self.confirmed = false
                            self.debugLabel.text = self.usernameIn.text! + " is already taken!"
                        }
                    }
                }
                
                return nil
            }
            
        }
        // Do any additional setup after loading the view.
    }
    
    @IBAction func textChangeListener(_ sender: UITextField) {
        usernameVersion += 1
        let thisVersion = usernameVersion
        let input = usernameIn.text
        self.debugLabel.text = "Checking username..."
        client.userHead(a: "uc", b: usernameIn.text?.lowercased()).continueWith(block:) {(task: AWSTask) -> Empty? in
            if task.error != nil{
                DispatchQueue.main.async {
                    if(thisVersion == self.usernameVersion){
                        self.confirmed = true
                        self.debugLabel.text = "Username available"
                        self.confirmedInput = input!
                    }
                }
            }
            else{
                DispatchQueue.main.async {
                    if(thisVersion == self.usernameVersion){
                        self.confirmed = false
                        self.debugLabel.text = self.usernameIn.text! + " is already taken!"
                    }
                }
            }
            
            return nil
        }
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
                case "goToPassword":
                    print("goToPassword")
                    guard let passwordVC = segue.destination as? PasswordViewController else {return}
                    passwordVC.birthday = birthday
                    passwordVC.username = confirmedInput
                case "backToBirthday":
                    print("backToBirthday")
                    guard let birthdayVC = segue.destination as? BirthdayViewController else {return}
                    birthdayVC.birthday = birthday
                    birthdayVC.username = usernameIn.text
                default:
                    print("default")
                    guard let passwordVC = segue.destination as? PasswordViewController else {return}
                    passwordVC.birthday = birthday
                    passwordVC.username = confirmedInput
            }
        }
    }
    
    @IBAction func nextTapped(_ sender: UIButton) {
        if confirmed && confirmedInput != nil {
            performSegue(withIdentifier: "goToPassword", sender: self)
        }
        
    }
    
    @IBAction func backTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "backToBirthday", sender: self)
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
