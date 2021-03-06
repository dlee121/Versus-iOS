//
//  SettingsViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 8/23/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseMessaging
import FacebookLogin
import PopupDialog

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var settingsItems = [String]()
    var isNative = false
    var emailIsSetup = false
    var currentUsername, currentEmail : String!
    var segueType = 0
    let logoutSegue = 1
    var emailSetUpButtonLock = false
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.alwaysBounceVertical = false
        currentUsername = UserDefaults.standard.string(forKey: "KEY_USERNAME")
        isNative = UserDefaults.standard.bool(forKey: "KEY_IS_NATIVE")
        if isNative {
            if let email = UserDefaults.standard.string(forKey: "KEY_EMAIL") {
                
                if email == "0" {
                    emailIsSetup = false
                    settingsItems = ["Log Out", "Blocked Users", "Contact Us","Set Up Email for Account Recovery", "About"]
                }
                else {
                    emailIsSetup = true
                    currentEmail = email
                    settingsItems = ["Log Out", "Blocked Users", "Contact Us", "Edit Email for Account Recovery", "About"]
                }
            }
            else {
                settingsItems = ["Log Out", "Blocked Users", "Contact Us", "Set Up Email for Account Recovery", "About"]
            }
        }
        else {
            settingsItems = ["Log Out", "Blocked Users", "Contact Us", "About"]
        }
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsItem", for: indexPath) as! SettingsItemTableViewCell
        
        cell.setCell(name: settingsItems[indexPath.row])
        
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            //Log Out
            Messaging.messaging().unsubscribe(fromTopic: currentUsername)
            //remove session data, log out firebase user, then segue back to start screen
            UserDefaults.standard.removeObject(forKey: "KEY_BLOCKS")
            UserDefaults.standard.removeObject(forKey: "KEY_BDAY")
            UserDefaults.standard.removeObject(forKey: "KEY_EMAIL")
            UserDefaults.standard.removeObject(forKey: "KEY_USERNAME")
            UserDefaults.standard.removeObject(forKey: "KEY_PI")
            UserDefaults.standard.removeObject(forKey: "KEY_IS_NATIVE")
            try! Auth.auth().signOut()
            
            let loginManager = LoginManager()
            loginManager.logOut()
            
            guard let window = UIApplication.shared.keyWindow else {
                return
            }
            
            guard let rootViewController = window.rootViewController else {
                return
            }
            
            let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let vc : StartViewController = storyboard.instantiateViewController(withIdentifier: "loginPage") as! StartViewController
            vc.view.frame = rootViewController.view.frame
            vc.view.layoutIfNeeded()
            
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = vc
            }, completion: nil)
            
        case 1:
            //Blocked Users
            performSegue(withIdentifier: "showBlockedUsers", sender: self)
            
        case 2: //Contact Us
            showContactUsDialog()
            
        case 3:
            if isNative {
                //Set Up Email. later, let's have it so that the name changes to "Edit Email" when email is already added
                showCustomDialog()
            }
            else {
                //About
                performSegue(withIdentifier: "settingToAbout", sender: self)
                
            }
        case 4:
            //About
            performSegue(withIdentifier: "settingToAbout", sender: self)
            
        default:
            break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let blockedUsersVC = segue.destination as? BlockedUsersViewController else {return}
        let view = blockedUsersVC.view //necessary for loading the view
        
        if let blockList = UserDefaults.standard.object(forKey: "KEY_BLOCKS") as? [String] {
            if blockList.count > 0 {
                blockedUsersVC.setUpBlockedUsersPage(blockedUsersList: blockList)
            }
            else {
                blockedUsersVC.setUpBlankPage()
            }
        }
        else {
            blockedUsersVC.setUpBlankPage()
        }
        
        
    }
    
    func showContactUsDialog(animated: Bool = true) {
        // Prepare the popup assets
        let message = "You can email us at:\ncontact@versusdaily.com"
        
        // Create the dialog
        let popup = PopupDialog(title: message, message: nil)
        
        // Create buttons
        let buttonOne = CancelButton(title: "OK") {
            print("You canceled the car dialog.")
        }
        
        popup.addButton(buttonOne)
        
        // Present dialog
        self.present(popup, animated: true, completion: nil)
        
    }
    
    func showCustomDialog(animated: Bool = true) {
        
        // Create a custom view controller
        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let emailSetupVC : EmailSetupVC = storyboard.instantiateViewController(withIdentifier: "emailSetupVC") as! EmailSetupVC
        let view = emailSetupVC.view
        emailSetupVC.setUpPWIn()
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
                print("OK clicked")
                let user = Auth.auth().currentUser
                var userEmail: String!
                let emailInput = emailSetupVC.textField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                
                
                if self.isEmail(email: emailInput){
                    
                    if emailSetupVC.emPwIn.text?.count == 0 {
                        //pop a toast "Please enter your password."
                        self.showToast(message: "Please enter your password.", length: 27)
                        self.emailSetUpButtonLock = false
                    }
                    else {
                        if self.emailIsSetup {
                            userEmail = self.currentEmail
                        }
                        else {
                            userEmail = self.currentUsername + "@versusbcd.com"
                        }
                        
                        
                        var credential = EmailAuthProvider.credential(withEmail: userEmail, password: emailSetupVC.emPwIn.text!)
                        
                        user?.reauthenticate(with: credential) { error in
                            if let error = error {
                                DispatchQueue.main.async {
                                    // pop a toast "Something went wrong. Please check your network connection and try again."
                                    self.showToast(message: "Please check your password", length: 26)
                                    self.emailSetUpButtonLock = false
                                }
                                
                            }
                            else {
                                // User re-authenticated.
                                DispatchQueue.main.async {
                                    //close popup
                                    self.dismiss(animated: true, completion: nil)
                                    //pop a toast "Setting up account recovery"
                                    self.showToast(message: "Setting up account recovery", length: 27)
                                }
                                
                                Auth.auth().currentUser?.updateEmail(to: emailInput) { (error) in
                                    
                                    if let error = error {
                                        DispatchQueue.main.async {
                                            self.showToastLongTime(message: "This email address is already in use", length: 36)
                                            self.emailSetUpButtonLock = false
                                        }
                                        
                                    }
                                    else {
                                        // pop a toast "Account recovery was set up successfully!"
                                        DispatchQueue.main.async {
                                            self.showToast(message: "Account recovery was set up successfully!", length: 41)
                                            self.emailSetUpButtonLock = false
                                            self.settingsItems[1] = "Edit Email for Account Recovery"
                                            self.tableView.reloadData()
                                        }
                                        UserDefaults.standard.set(emailInput, forKey: "KEY_EMAIL")
                                        self.currentEmail = emailInput
                                        //write the new email address to user's em field in ES
                                        VSVersusAPIClient.default().setemailGet(c: emailInput, a: "sem", b: self.currentUsername)
                                        
                                    }
                                    
                                }
                            }
                        }
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

    @IBAction func closeButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    

}
