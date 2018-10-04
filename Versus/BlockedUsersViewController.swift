//
//  BlockedUsersViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 10/4/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import FirebaseDatabase
import PopupDialog

class BlockedUsersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, BlockedUsersDelegator {
    
    @IBOutlet weak var coverLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    var usernames = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        // Do any additional setup after loading the view.
    }
    
    func setUpBlankPage() {
        coverLabel.isHidden = false
        
    }
    
    func setUpBlockedUsersPage(blockedUsersList : [String]) {
        coverLabel.isHidden = true
        usernames = blockedUsersList
        tableView.reloadData()
    }
    

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usernames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "blockedUserCell", for: indexPath) as! BlockedUserTableViewCell
        cell.username.text = usernames[indexPath.row]
        cell.delegate = self
        cell.rowNumber = indexPath.row
        
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        
        return cell
    }
    
    func unblockUser(username: String, rowNumber: Int) {
        
        // Prepare the popup assets
        let title = "Unblock \(username)?"
        let message = ""
        
        // Create the dialog
        let popup = PopupDialog(title: title, message: message)
        
        // Create buttons
        let buttonOne = DefaultButton(title: "No", action: nil)
        
        // This button will not the dismiss the dialog
        let buttonTwo = DefaultButton(title: "Yes") {
            var myUsername = UserDefaults.standard.string(forKey: "KEY_USERNAME")!
            
            var usernameHash : Int32
            if(myUsername.count < 5){
                usernameHash = myUsername.hashCode()
            }
            else{
                var hashIn = ""
                hashIn.append(myUsername[0])
                hashIn.append(myUsername[myUsername.count-2])
                hashIn.append(myUsername[1])
                hashIn.append(myUsername[myUsername.count-1])
                
                usernameHash = hashIn.hashCode()
            }
            
            let blockPath = "\(usernameHash)/\(myUsername)/blocked/\(username)"
            Database.database().reference().child(blockPath).removeValue()
            
            self.usernames.remove(at: rowNumber)
            self.tableView.reloadData()
            
            if self.usernames.count == 0 {
                self.coverLabel.isHidden = false
            }
            
            var blockListArray = [String]()
            
            if let blockList = UserDefaults.standard.object(forKey: "KEY_BLOCKS") as? [String] {
                blockListArray = blockList
            }
            
            var i = 0
            for name in blockListArray {
                if name == username {
                    blockListArray.remove(at: i)
                }
                i += 1
            }
            
            UserDefaults.standard.set(blockListArray, forKey: "KEY_BLOCKS")
            
            let str = "Unblocked \(username)."
            self.showToast(message: str, length: str.count + 2)
        }
        
        popup.addButtons([buttonOne, buttonTwo])
        popup.buttonAlignment = .horizontal
        
        // Present dialog
        self.present(popup, animated: true, completion: nil)
        
    }
    
    
    @IBAction func closePage(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
}


protocol BlockedUsersDelegator {
    func unblockUser(username : String, rowNumber : Int)
}
