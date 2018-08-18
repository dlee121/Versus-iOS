//
//  NotificationsViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/13/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import FirebaseDatabase

class NotificationsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var notificationItems = [NotificationItem]()
    let apiClient = VSVersusAPIClient.default()
    var userNotificationsPath : String!
    var ref : DatabaseReference!
    
    let TYPE_U = 0 //new comment upvote notification
    let TYPE_C = 1 //new comment reply notification
    let TYPE_V = 2 //new post vote notification
    let TYPE_R = 3 //new post root comment notification
    let TYPE_F = 4 //new follower notification
    let TYPE_M = 5 //new medal notification
    let TYPE_EM = 6 //for password reset email setup notification
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Notifications"
        ref = Database.database().reference()
        var currentUsername = UserDefaults.standard.string(forKey: "KEY_USERNAME")
        userNotificationsPath = getUsernameHash(username: currentUsername!)+"/"+currentUsername!+"/n/"
        ref.child(userNotificationsPath).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            
            let value = snapshot.value as? [String : [String : Int]]
            if value != nil {
                let atomicCounter = AtomicInteger(value: value!.count)
                for notificationType in value! {
                    switch notificationType.key {
                    case "c":
                        var cCount = notificationType.value.count
                        if cCount == 0 {
                            if atomicCounter.decrementAndGet() == 0 {
                                self.finalizeList()
                            }
                        }
                        
                        for child in notificationType.value {
                            let childKeySplit = child.key.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)
                            let commentID: String = String(childKeySplit[0])
                            var commentContent: String = String(childKeySplit[1])
                            
                            self.ref.child(self.userNotificationsPath+"c/"+child.key).queryOrderedByValue().queryLimited(toLast: 8).observeSingleEvent(of: .value, with: { (dataSnapshot) in
                                var usernames = ""
                                var i = dataSnapshot.childrenCount
                                var timeValue = Int(NSDate().timeIntervalSince1970)
                                
                                let grandchildren = snapshot.value as? [String : Int]
                                for grandchild in grandchildren! {
                                    usernames.append(grandchild.key + ", ")
                                    i -= 1
                                    if i == 0 {
                                        timeValue = grandchild.value
                                    }
                                }
                                
                                if usernames.count >= 26 {
                                    usernames = String(usernames[0 ... 25])
                                    if let lastIndex = usernames.range(of: ",", options: .backwards)?.lowerBound {
                                        usernames = String(usernames[0 ..< usernames.distance(from: usernames.startIndex, to: lastIndex)])
                                        usernames.append("...")
                                    }
                                    else {
                                        usernames.append("...")
                                    }
                                }
                                else {
                                    if let lastIndex = usernames.range(of: ",", options: .backwards)?.lowerBound {
                                        usernames = String(usernames[0 ..< usernames.distance(from: usernames.startIndex, to: lastIndex)])
                                    }
                                }
                                
                                let body = usernames + "\nreplied to your comment, \"" + commentContent.replacingOccurrences(of: "^", with: " ") + "\""
                                self.notificationItems.append(NotificationItem(body: body, type: self.TYPE_C, payload: commentID, timestamp: timeValue, key: dataSnapshot.key))
                                
                                cCount -= 1
                                if cCount == 0 {
                                    if atomicCounter.decrementAndGet() == 0 {
                                        self.finalizeList()
                                    }
                                }
                                
                            }){ (error) in
                                print(error.localizedDescription)
                                
                            }
                        }
                        
                        
                        
                    case "f":
                        
                    case "m":
                        
                    case "r":
                        
                    case "u":
                        
                    case "v":
                        
                    case "em":
                        
                    default:
                        break
                        
                    }
                    
                    
                    
                }
            }
            
            // ...
        }) { (error) in
            print(error.localizedDescription)
        }

        // Do any additional setup after loading the view.
    }

    func finalizeList() {
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notificationItems.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "notificationItem", for: indexPath) as? NotificationsTableViewCell
        cell!.setCell()
        return cell!
    }
    
    //initial loader that retrieves all notifications and sorts them into the list, and realtime addition/change listner for each notification branch to add new items as they come
    func initialLoad(){
        var atomicCounter = AtomicInteger(value: <#T##Int#>)
        
        
        
        
        
    }
    
    func getUsernameHash(username : String) -> String {
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
        
        return "\(usernameHash)"
    }

    

}
