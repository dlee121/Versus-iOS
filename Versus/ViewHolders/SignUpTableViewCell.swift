//
//  SignUpTableViewCell.swift
//  Versus
//
//  Created by Dongkeun Lee on 9/17/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class SignUpTableViewCell: UITableViewCell {

    @IBOutlet weak var usernameIn: UITextField!
    @IBOutlet weak var passwordIn: UITextField!
    @IBOutlet weak var legalText: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var createAccountButton: UIButton!
    
    @IBOutlet weak var passwordInHeight: NSLayoutConstraint!
    @IBOutlet weak var passwordLabelHeight: NSLayoutConstraint!
    var confirmedUsername, confirmedPW : String!
    var usernameConfirmed : Bool!
    var native : Bool!
    
    var delegate : SignUpDelegator!
    var usernameVersion : Int = 0
    var unauthClient : VSVersusAPIClient!
    
    func setCell(isNative : Bool, delegator : SignUpDelegator) {
        
        if isNative {
            passwordInHeight.constant = 38
            passwordLabelHeight.constant = 17
        }
        else {
            passwordInHeight.constant = 0
            passwordLabelHeight.constant = 0
        }
        
        native = isNative
        delegate = delegator
        
        let credentialProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: "us-east-1:88614505-c8df-4dce-abd8-79a0543852ff")
        credentialProvider.clearCredentials()
        let configurationAuth = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialProvider)
        //unauth config is stored in individual client instances and not in default, which is reserved for auth config
        unauthClient = VSVersusAPIClient(configuration: configurationAuth!)
        
        if native {
            if confirmedUsername != nil && confirmedPW != nil {
                activateSignUpButton()
            }
            else {
                deactivateSignUpButton()
            }
        }
        else {
            if confirmedUsername != nil {
                activateSignUpButton()
            }
            else {
                deactivateSignUpButton()
            }
        }
        
    }
    
    
    func activateSignUpButton(){
        createAccountButton.isEnabled = true
        createAccountButton.backgroundColor = UIColor(red: 0, green: 0.478, blue: 1, alpha: 1)
    }
    
    func deactivateSignUpButton(){
        createAccountButton.isEnabled = false
        createAccountButton.backgroundColor = UIColor(red: 0.666, green: 0.666, blue: 0.666, alpha: 1)
    }
    
    @IBAction func usernameChangeListner(_ sender: UITextField) {
        deactivateSignUpButton()
        let input = usernameIn.text
        
        if characterChecker(input: input!) {
            
            usernameVersion += 1
            let thisVersion = usernameVersion
            
            usernameLabel.text = "Checking username..."
            unauthClient.userHead(a: "uc", b: usernameIn.text?.lowercased()).continueWith(block:) {(task: AWSTask) -> Empty? in
                if task.error != nil{
                    DispatchQueue.main.async {
                        if(thisVersion == self.usernameVersion){
                            self.usernameConfirmed = true
                            self.usernameLabel.textColor = UIColor.black
                            self.usernameLabel.text = "Username available"
                            self.confirmedUsername = input!
                            if self.native {
                                if self.confirmedPW != nil && self.confirmedPW.count >= 6 {
                                    self.activateSignUpButton()
                                }
                            }
                            else {
                                self.activateSignUpButton()
                            }
                        }
                    }
                }
                else{
                    DispatchQueue.main.async {
                        if(thisVersion == self.usernameVersion){
                            self.usernameConfirmed = false
                            self.usernameLabel.textColor = UIColor(named: "noticeRed")
                            self.usernameLabel.text = self.usernameIn.text! + " is already taken!"
                        }
                    }
                }
                
                return nil
            }
        }
        else{
            if input!.isEmpty{
                usernameConfirmed = false
                usernameLabel.text = ""
            }
            else{
                usernameConfirmed = false
                usernameLabel.textColor = UIColor(named: "noticeRed")
                usernameLabel.text = "Can only contain letters, numbers, and the following special characters: '-', '_', '~', and '%'"
            }
        }
    }
    
    func characterChecker(input : String) -> Bool {
        return !input.isEmpty && input.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
    }
    
    
    @IBAction func pwChangeListener(_ sender: UITextField) {
        deactivateSignUpButton()
        confirmedPW = nil
        if let input = passwordIn.text{
            if input.count > 0{
                if input.count >= 6{
                    if input.prefix(1) == " "{
                        passwordLabel.text = "Password cannot start with blank space"
                        passwordLabel.textColor = UIColor(named: "noticeRed")
                    }
                    else if input.suffix(1) == " "{
                        passwordLabel.text = "Password cannot end with blank space"
                        passwordLabel.textColor = UIColor(named: "noticeRed")
                    }
                    else{
                        passwordStrengthCheck(pw: input)
                        confirmedPW = input
                        if usernameConfirmed != nil && usernameConfirmed {
                            activateSignUpButton()
                        }
                    }
                }
                else{
                    passwordLabel.text = "Must be at least 6 characters"
                    passwordLabel.textColor = UIColor(named: "noticeRed")
                }
            }
            else{
                passwordLabel.text = ""
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
            passwordLabel.textColor = UIColor(named: "noticeRed")
            passwordLabel.text = "Password strength: weak"
        case 1:
            passwordLabel.textColor = UIColor(named: "noticeRed")
            passwordLabel.text = "Password strength: weak"
        case 2:
            passwordLabel.text = "Password strength: medium"
            passwordLabel.textColor = UIColor(named: "noticeYellow")
        case 3:
            passwordLabel.text = "Password strength: good"
            passwordLabel.textColor = UIColor(named: "noticeGreen")
        case 4:
            passwordLabel.text = "Password strength: strong"
            passwordLabel.textColor = UIColor(named: "noticeGreen")
        default:
            passwordLabel.text = "Password strength: medium"
            passwordLabel.textColor = UIColor(named: "noticeYellow")
        }
    }
    
    
    
    @IBAction func createAccountButtonTapped(_ sender: UIButton) {
        if native {
            if let username = usernameIn.text {
                if let pw = passwordIn.text {
                    delegate.signUpButtonTapped(username: username, pw: pw)
                }
                else {
                    delegate.showSUVCToast(text: "Please enter a valid password")
                }
            }
            else {
                delegate.showSUVCToast(text: "Please enter a valid username")
            }
        }
        else {
            if let username = usernameIn.text {
                delegate.signUpButtonTapped(username: username, pw: nil)
            }
            else {
                delegate.showSUVCToast(text: "Please enter a valid username")
            }
        }
    }
    
}
