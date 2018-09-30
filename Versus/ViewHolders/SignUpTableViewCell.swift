//
//  SignUpTableViewCell.swift
//  Versus
//
//  Created by Dongkeun Lee on 9/17/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import ActiveLabel

class SignUpTableViewCell: UITableViewCell, UITextFieldDelegate {

    @IBOutlet weak var usernameIn: UITextField!
    @IBOutlet weak var passwordIn: UITextField!
    @IBOutlet weak var legalText: ActiveLabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var createAccountButton: UIButton!
    
    @IBOutlet weak var createAccountIndicator: UIActivityIndicatorView!
    @IBOutlet weak var passwordInHeight: NSLayoutConstraint!
    @IBOutlet weak var passwordLabelHeight: NSLayoutConstraint!
    var confirmedUsername, confirmedPW : String!
    var usernameConfirmed : Bool!
    var native : Bool!
    
    var delegate : SignUpDelegator!
    var usernameVersion : Int = 0
    var unauthClient : VSVersusAPIClient!
    
    //let label = ActiveLabel()
    
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
        
        if native {
            let button = UIButton(type: .custom)
            button.setImage(UIImage(named: "eye.png"), for: .normal)
            //button.imageEdgeInsets = UIEdgeInsetsMake(0, -16, 0, 0)
            button.frame = CGRect(x: CGFloat(passwordIn.frame.size.width - 25), y: CGFloat(5), width: CGFloat(25), height: CGFloat(25))
            button.addTarget(self, action: #selector(self.pwtoggle), for: .touchUpInside)
            passwordIn.rightView = button
            passwordIn.rightViewMode = .always
        }
        
        usernameIn.delegate = self
        passwordIn.delegate = self
        
        if native {
            usernameIn.returnKeyType = .next
            passwordIn.returnKeyType = .go
        }
        else {
            usernameIn.returnKeyType = .go
        }
        
        
        let customType = ActiveType.custom(pattern: "\\sTerms and Policies\\b")
        legalText.enabledTypes.append(customType)
        
        legalText.customize { label in
            legalText.customColor[customType] = UIColor(red: 0.0, green: 122.0/255, blue: 1, alpha: 1)
            
            legalText.handleCustomTap(for: customType) { _ in
                guard let url = URL(string: "https://www.versusdaily.com/terms-and-policies") else { return }
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url)
                } else {
                    // Fallback on earlier versions
                    UIApplication.shared.openURL(url)
                }
            }
        }
        
    }
    
    func lockCreateAccountButton() {
        createAccountIndicator.startAnimating()
        createAccountButton.isEnabled = false
    }
    
    func unlockCreateAccountButton() {
        createAccountIndicator.stopAnimating()
        createAccountButton.isEnabled = true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if native {
            if textField == usernameIn {
                textField.resignFirstResponder()
                passwordIn.becomeFirstResponder()
            } else if textField == passwordIn {
                if createAccountButton.isEnabled {
                    createAccountButtonTapped(createAccountButton)
                }
                else {
                    delegate.showSUVCToast(text: "Please enter a valid username and password")
                }
            }
        }
        else {
            if textField == usernameIn {
                if createAccountButton.isEnabled {
                    createAccountButtonTapped(createAccountButton)
                }
                else {
                    delegate.showSUVCToast(text: "Please enter a valid username")
                }
            }
        }
        
        return true
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
    
    
    func activateSignUpButton(){
        createAccountButton.isEnabled = true
        createAccountButton.backgroundColor = UIColor(red: 0, green: 0.478, blue: 1, alpha: 1)
    }
    
    func deactivateSignUpButton(){
        createAccountButton.isEnabled = false
        createAccountButton.backgroundColor = UIColor(red: 0.666, green: 0.666, blue: 0.666, alpha: 1)
    }
    
    @IBAction func usernameChangeListner(_ sender: UITextField) {
        usernameVersion += 1
        deactivateSignUpButton()
        let input = usernameIn.text
        
        if characterChecker(input: input!) {
            
            let thisVersion = usernameVersion
            
            usernameLabel.text = "Checking username..."
            unauthClient.userHead(a: "uc", b: input!).continueWith(block:) {(task: AWSTask) -> Empty? in
                if task.error != nil && input!.lowercased() != "deleted" && input!.lowercased() != "ad" {
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
                            if #available(iOS 11.0, *) {
                                self.usernameLabel.textColor = UIColor(named: "noticeRed")
                            } else {
                                // Fallback on earlier versions
                                self.usernameLabel.textColor = UIColor(red: 0.961, green: 0.235, blue: 0.333, alpha: 1.0)
                            }
                            self.usernameLabel.text = input! + " is already taken!"
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
                if #available(iOS 11.0, *) {
                    usernameLabel.textColor = UIColor(named: "noticeRed")
                } else {
                    // Fallback on earlier versions
                    self.usernameLabel.textColor = UIColor(red: 0.961, green: 0.235, blue: 0.333, alpha: 1.0)
                    
                }
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
                        if #available(iOS 11.0, *) {
                            passwordLabel.textColor = UIColor(named: "noticeRed")
                        } else {
                            // Fallback on earlier versions
                            self.usernameLabel.textColor = UIColor(red: 0.961, green: 0.235, blue: 0.333, alpha: 1.0)
                        }
                    }
                    else if input.suffix(1) == " "{
                        passwordLabel.text = "Password cannot end with blank space"
                        if #available(iOS 11.0, *) {
                            passwordLabel.textColor = UIColor(named: "noticeRed")
                            self.usernameLabel.textColor = UIColor(red: 0.961, green: 0.235, blue: 0.333, alpha: 1.0)
                        } else {
                            // Fallback on earlier versions
                        }
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
                    if #available(iOS 11.0, *) {
                        passwordLabel.textColor = UIColor(named: "noticeRed")
                    } else {
                        // Fallback on earlier versions
                        self.usernameLabel.textColor = UIColor(red: 0.961, green: 0.235, blue: 0.333, alpha: 1.0)
                    }
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
            if #available(iOS 11.0, *) {
                passwordLabel.textColor = UIColor(named: "noticeRed")
            } else {
                // Fallback on earlier versions
                self.usernameLabel.textColor = UIColor(red: 0.961, green: 0.235, blue: 0.333, alpha: 1.0)
            }
            passwordLabel.text = "Password strength: weak"
        case 1:
            if #available(iOS 11.0, *) {
                passwordLabel.textColor = UIColor(named: "noticeRed")
            } else {
                // Fallback on earlier versions
                self.usernameLabel.textColor = UIColor(red: 0.961, green: 0.235, blue: 0.333, alpha: 1.0)
            }
            passwordLabel.text = "Password strength: weak"
        case 2:
            passwordLabel.text = "Password strength: medium"
            if #available(iOS 11.0, *) {
                passwordLabel.textColor = UIColor(named: "noticeYellow")
            } else {
                // Fallback on earlier versions
                self.usernameLabel.textColor = UIColor(red: 1.0, green: 0.867, blue: 0.0, alpha: 1.0)
            }
        case 3:
            passwordLabel.text = "Password strength: good"
            if #available(iOS 11.0, *) {
                passwordLabel.textColor = UIColor(named: "noticeGreen")
            } else {
                // Fallback on earlier versions
                self.usernameLabel.textColor = UIColor(red: 0.094, green: 0.749, blue: 0.184, alpha: 1.0)
            }
        case 4:
            passwordLabel.text = "Password strength: strong"
            if #available(iOS 11.0, *) {
                passwordLabel.textColor = UIColor(named: "noticeGreen")
            } else {
                // Fallback on earlier versions
                self.usernameLabel.textColor = UIColor(red: 0.094, green: 0.749, blue: 0.184, alpha: 1.0)
            }
        default:
            passwordLabel.text = "Password strength: medium"
            if #available(iOS 11.0, *) {
                passwordLabel.textColor = UIColor(named: "noticeYellow")
            } else {
                // Fallback on earlier versions
                self.usernameLabel.textColor = UIColor(red: 1.0, green: 0.867, blue: 0.0, alpha: 1.0)
            }
        }
    }
    
    
    
    @IBAction func createAccountButtonTapped(_ sender: UIButton) {
        if native {
            if confirmedUsername != nil {
                if confirmedPW != nil {
                    delegate.signUpButtonTapped(username: confirmedUsername, pw: confirmedPW)
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
            if confirmedUsername != nil {
                delegate.signUpButtonTapped(username: confirmedUsername, pw: nil)
            }
            else {
                delegate.showSUVCToast(text: "Please enter a valid username")
            }
        }
    }
    
}
