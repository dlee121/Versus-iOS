//
//  BlockedUsersViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 10/4/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class BlockedUsersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, BlockedUsersDelegator {
    
    @IBOutlet weak var coverLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    var usernames = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func setUpBlankPage() {
        coverLabel.isHidden = true
    }
    
    func setUpBlockedUsersPage(blockedUsersList : [String]) {
        coverLabel.isHidden = false
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
        
        return cell
    }
    
    func unblockUser(username: String, rowNumber: Int) {
        //hi
        print("unblock \(username) at \(rowNumber)")
    }
    
    
    @IBAction func closePage(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
}


protocol BlockedUsersDelegator {
    func unblockUser(username : String, rowNumber : Int)
}
