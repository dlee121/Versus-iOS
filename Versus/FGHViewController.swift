//
//  FGHViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/26/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class FGHViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var usernames = [String]()
    var profileImageVersions = [String : Int]()
    var apiClient = VSVersusAPIClient.default()
    var fromIndex : Int!
    var tappedUsername : String!
    var fORg : Int!
    let f = 0
    let g = 1
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if fORg == f {
            navigationItem.title = "Followers"
        }
        else {
            navigationItem.title = "Following"
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUpFPage(followers : [String]){
        var index = 0
        var payload = "{\"ids\":["
        usernames = followers
        profileImageVersions.removeAll()
        
        if(followers.count > 0){
            for username in followers {
                if index == 0 {
                    payload.append("\"" + username + "\"")
                }
                else{
                    payload.append(",\"" + username + "\"")
                }
                index += 1
            }
            payload.append("]}")
            
            self.apiClient.pivGet(a: "pis", b: payload.lowercased()).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                if task.error != nil {
                    DispatchQueue.main.async {
                        print(task.error!)
                    }
                }
                
                if let results = task.result?.docs {
                    for item in results {
                        self.profileImageVersions[item.id!] = item.source!.pi!.intValue
                    }
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
                return nil
            }
            
            
        }
        else{
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
    }
    
    func setUpGPage(followings : [String]){
        var index = 0
        var payload = "{\"ids\":["
        usernames = followings
        profileImageVersions.removeAll()
        
        if(followings.count > 0){
            for username in followings {
                if index == 0 {
                    payload.append("\"" + username + "\"")
                }
                else{
                    payload.append(",\"" + username + "\"")
                }
                index += 1
            }
            payload.append("]}")
            
            
            self.apiClient.pivGet(a: "pis", b: payload.lowercased()).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                if task.error != nil {
                    DispatchQueue.main.async {
                        print(task.error!)
                    }
                }
                
                if let results = task.result?.docs {
                    for item in results {
                        self.profileImageVersions[item.id!] = item.source?.pi?.intValue
                    }
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
                return nil
            }
            
            
        }
        else{
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usernames.count
    }
    
    /*
     func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
     if(indexPath.row == 0){
     return CGFloat(116.0)
     }
     return CGFloat(102.0)
     }
     */
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tappedUsername = usernames[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "fghToProfile", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let profileVC = segue.destination as? ProfileViewController else {return}
        profileVC.currentUsername = tappedUsername
        //let backItem = UIBarButtonItem()
        //backItem.title = "Leader..."
        //navigationItem.backBarButtonItem = backItem
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fghItem", for: indexPath) as? FGHTableViewCell
        let username = usernames[indexPath.row]
        if let piv = profileImageVersions[username.lowercased()] {
            cell!.setCell(username: username, profileImageVersion: piv)
        }
        else{
            cell!.setCell(username: username, profileImageVersion: 0)
        }
        
        return cell!
    }

}
