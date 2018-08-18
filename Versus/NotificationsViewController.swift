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

    @IBOutlet weak var tableView: UITableView!
    
    
    var notificationItems : [NotificationItem]!
    let apiClient = VSVersusAPIClient.default()
    var userNotificationsPath : String!
    var ref : DatabaseReference!
    var initialLoadExecuted = false
    var initialLoadLock = false
    var initialLoaderHandle : UInt!
    
    let TYPE_U = 0 //new comment upvote notification
    let TYPE_C = 1 //new comment reply notification
    let TYPE_V = 2 //new post vote notification
    let TYPE_R = 3 //new post root comment notification
    let TYPE_F = 4 //new follower notification
    let TYPE_M = 5 //new medal notification
    let TYPE_EM = 6 //for password reset email setup notification
    
    override func viewDidLoad() {
        super.viewDidLoad()
        notificationItems = [NotificationItem]()
        navigationItem.title = "Notifications"
        initialLoadExecuted = false
        initialLoadLock = false
        ref = Database.database().reference()
        var currentUsername = UserDefaults.standard.string(forKey: "KEY_USERNAME")
        userNotificationsPath = getUsernameHash(username: currentUsername!)+"/"+currentUsername!+"/n/"
        if !initialLoadExecuted {
            initialLoadExecuted = true
            
            initialLoaderHandle = ref.child(userNotificationsPath).observe(DataEventType.value, with: { (snapshot) in
                if !self.initialLoadLock {
                    self.initialLoadLock = true
                    let value = snapshot.value as? [String : AnyObject]
                    if value != nil {
                        let atomicCounter = AtomicInteger(value: value!.count)
                        for notificationType in value! { //notificationType = notificationTypeKey : [notificationKey : [Username : TimeValue]]
                            switch notificationType.key {
                            case "c":
                                let section = notificationType.value as! [String : [String : Int]]
                                
                                var cCount = section.count
                                if cCount == 0 {
                                    if atomicCounter.decrementAndGet() == 0 {
                                        self.finalizeList()
                                    }
                                }
                                
                                for child in section{
                                    let childKeySplit = child.key.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)
                                    let commentID: String = String(childKeySplit[0])
                                    let commentContent: String = String(childKeySplit[1])
                                    
                                    self.ref.child(self.userNotificationsPath+"c/"+child.key).queryOrderedByValue().queryLimited(toLast: 8).observeSingleEvent(of: .value, with: { (dataSnapshot) in
                                        var usernames = ""
                                        var i = dataSnapshot.childrenCount
                                        var timeValue = Int(NSDate().timeIntervalSince1970)
                                        
                                        let grandchildren = dataSnapshot.value as? [String : Int]
                                        for grandchild in grandchildren! {
                                            usernames.append(grandchild.key + ", ")
                                            i -= 1
                                            if i == 0 {
                                                timeValue = grandchild.value
                                            }
                                        }
                                        
                                        if usernames.count >= 26 {
                                            usernames = String(usernames[0 ... 25])
                                            if String(usernames[25]) == "," {
                                                usernames = String(usernames[0 ..< 25])
                                                usernames.append("...")
                                            }
                                            else if String(usernames[24]) == "," {
                                                usernames = String(usernames[0 ..< 24])
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
                                            if atomicCounter.decrementAndGet() == 0{
                                                self.finalizeList()
                                            }
                                        }
                                        
                                    }){ (error) in
                                        print(error.localizedDescription)
                                    }
                                }
                                
                                
                            case "f":
                                self.ref.child(self.userNotificationsPath+"f/").queryOrderedByValue().queryLimited(toLast: 8).observeSingleEvent(of: .value, with: { (dataSnapshot) in
                                    var usernames = ""
                                    var i = dataSnapshot.childrenCount
                                    var timeValue = Int(NSDate().timeIntervalSince1970)
                                    
                                    let grandchildren = dataSnapshot.value as? [String : Int]
                                    for grandchild in grandchildren! {
                                        usernames.append(grandchild.key + ", ")
                                        i -= 1
                                        if i == 0 {
                                            timeValue = grandchild.value
                                        }
                                    }
                                    
                                    if usernames.count >= 26 {
                                        usernames = String(usernames[0 ... 25])
                                        if String(usernames[25]) == "," {
                                            usernames = String(usernames[0 ..< 25])
                                            usernames.append("...")
                                        }
                                        else if String(usernames[24]) == "," {
                                            usernames = String(usernames[0 ..< 24])
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
                                    
                                    let body = usernames + "\nstarted following you!"
                                    self.notificationItems.append(NotificationItem(body: body, type: self.TYPE_F, timestamp: timeValue, key: dataSnapshot.key))
                                    
                                    if atomicCounter.decrementAndGet() == 0 {
                                        self.finalizeList()
                                    }
                                    
                                }){ (error) in
                                    print(error.localizedDescription)
                                }
                                
                            case "m":
                                
                                
                                /*
                                 for(DataSnapshot child : typeChild.getChildren()){
                                 String commentID = child.getKey();
                                 String[] args = child.getValue(String.class).split(":",3);
                                 String medalType = args[0];
                                 long timeValue = Long.parseLong(args[1]);
                                 String commentContent = args[2].replace('^', ' ');
                                 String header;
                                 switch (medalType){
                                 case "g":
                                 header = "Congratulations! You won a Gold Medal for,";
                                 break;
                                 case "s":
                                 header = "Congratulations! You won a Silver Medal for,";
                                 break;
                                 case "b":
                                 header = "Congratulations! You won a Bronze Medal for,";
                                 break;
                                 default:
                                 header = "Congratulations! You won a medal for,";
                                 break;
                                 }
                                 
                                 String body = header + "\n\""+commentContent+"\"";
                                 notificationItems.add(new NotificationItem(body, TYPE_M, commentID, timeValue, medalType, child.getKey()));
                                 }
                                 if(typeChildCount.decrementAndGet() == 0){
                                 finalizeList();
                                 }
                                 */
                                
                                //placeholder
                                if atomicCounter.decrementAndGet() == 0{
                                    self.finalizeList()
                                }
                                
                            case "r":
                                //placeholder
                                if atomicCounter.decrementAndGet() == 0{
                                    self.finalizeList()
                                }
                                
                            case "u":
                                //placeholder
                                if atomicCounter.decrementAndGet() == 0{
                                    self.finalizeList()
                                }
                                
                            case "v":
                                //placeholder
                                if atomicCounter.decrementAndGet() == 0{
                                    self.finalizeList()
                                }
                                
                            case "em":
                                //placeholder
                                if atomicCounter.decrementAndGet() == 0{
                                    self.finalizeList()
                                }
                                
                            default:
                                break
                                
                            }
                            
                            
                            
                        }
                    }
                    
                    // ...
                    
                }
                
            }) { (error) in
                print(error.localizedDescription)
            }
            
            
        }
    }

    func finalizeList() {
        tableView.reloadData()
        
        //we use a regular listener (as opposed to single-use ones) to take advantage of the caching while querying the subtrees of the notifications path
        ref.removeObserver(withHandle: initialLoaderHandle)
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
        cell!.setCell(item: notificationItems[indexPath.row])
        return cell!
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
