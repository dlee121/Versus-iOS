//
//  SettingsViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 8/23/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMessaging

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var settingsItems = [String]()
    var isNative = false
    var currentUsername : String!
    var segueType = 0
    let logoutSegue = 1
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.alwaysBounceVertical = false
        currentUsername = UserDefaults.standard.string(forKey: "KEY_USERNAME")
        isNative = UserDefaults.standard.bool(forKey: "KEY_IS_NATIVE")
        if isNative {
            if let email = UserDefaults.standard.string(forKey: "KEY_EMAIL") {
                if email == "0" {
                    settingsItems = ["Log Out", "Set Up Email for Account Recovery", "About"]
                }
                else {
                    settingsItems = ["Log Out", "Edit Email for Account Recovery", "About"]
                }
            }
            else {
                settingsItems = ["Log Out", "Set Up Email for Account Recovery", "About"]
            }
        }
        else {
            settingsItems = ["Log Out", "About"]
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
        switch indexPath.row {
        case 0:
            //Log Out
            Messaging.messaging().unsubscribe(fromTopic: currentUsername)
            //remove session data, log out firebase user, then segue back to start screen
            UserDefaults.standard.removeObject(forKey: "KEY_BDAY")
            UserDefaults.standard.removeObject(forKey: "KEY_EMAIL")
            UserDefaults.standard.removeObject(forKey: "KEY_USERNAME")
            UserDefaults.standard.removeObject(forKey: "KEY_PI")
            UserDefaults.standard.removeObject(forKey: "KEY_IS_NATIVE")
            try! Auth.auth().signOut()
            segueType = logoutSegue
            //performSegue(withIdentifier: "logOutToStart", sender: self)
            //self.view.window!.rootViewController?.dismiss(animated: false, completion: nil)
            
            let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let vc : ViewController = storyboard.instantiateViewController(withIdentifier: "loginPage") as! ViewController
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.window = UIWindow(frame: UIScreen.main.bounds)
            appDelegate.window?.rootViewController = vc
            appDelegate.window?.makeKeyAndVisible()

            break
        case 1:
            if isNative {
                //Set Up Email. later, let's have it so that the name changes to "Edit Email" when email is already added
                
            }
            
            
            break
        case 2:
            //
            break
        default:
            break
        }
    }
    

    @IBAction func closeButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    

}
