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
                                    let commentID = String(childKeySplit[0])
                                    var commentContent = String(childKeySplit[1].replacingOccurrences(of: "^", with: " "))
                                    
                                    if commentContent.count > 25 && commentContent[commentContent.count - 3 ... commentContent.count - 1] == "   " {
                                        commentContent = commentContent[0 ... commentContent.count - 4].trimmingCharacters(in: .whitespaces) + "..."
                                    }
                                    
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
                                        
                                        let body = usernames + "\nreplied to your comment, \"" + commentContent + "\""
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
                                let section = notificationType.value as! [String : String]
                                for child in section {
                                    let commentID = child.key
                                    let childKeySplit = child.value.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: true)
                                    let medalType = String(childKeySplit[0])
                                    let timeValue = Int(childKeySplit[1])
                                    var commentContent = String(childKeySplit[2].replacingOccurrences(of: "^", with: " "))
                                    
                                    if commentContent.count > 25 && commentContent[commentContent.count - 3 ... commentContent.count - 1] == "   " {
                                        commentContent = commentContent[0 ... commentContent.count - 4].trimmingCharacters(in: .whitespaces) + "..."
                                    }
                                    
                                    var header : String!
                                    
                                    switch medalType {
                                    case "g":
                                        header = "Congratulations! You won a Gold Medal for,"
                                    case "s":
                                        header = "Congratulations! You won a Silver Medal for,"
                                    case "b":
                                        header = "Congratulations! You won a Bronze Medal for,"
                                    default:
                                        header = "Congratulations! You won a medal for,"
                                    }
                                    
                                    let body = header + "\n\""+commentContent+"\""
                                    self.notificationItems.append(NotificationItem(body: body, type: self.TYPE_M, payload: commentID, timestamp: timeValue!, medalType: medalType, key: commentID))
                                    
                                }
                                
                                if atomicCounter.decrementAndGet() == 0{
                                    self.finalizeList()
                                }
                                
                            case "r":
                                let section = notificationType.value as! [String : [String : Int]]
                                
                                var rCount = section.count
                                if rCount == 0 {
                                    if atomicCounter.decrementAndGet() == 0 {
                                        self.finalizeList()
                                    }
                                }
                                
                                for child in section{
                                    let childKeySplit = child.key.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: true)
                                    let postID = String(childKeySplit[0])
                                    let redName = String(childKeySplit[1].replacingOccurrences(of: "^", with: " "))
                                    let blueName = String(childKeySplit[2].replacingOccurrences(of: "^", with: " "))
                                    
                                    self.ref.child(self.userNotificationsPath+"r/"+child.key).queryOrderedByValue().queryLimited(toLast: 8).observeSingleEvent(of: .value, with: { (dataSnapshot) in
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
                                        
                                        let body = usernames + "\ncommented on \"" + redName + " vs. " + blueName + "\""
                                        self.notificationItems.append(NotificationItem(body: body, type: self.TYPE_R, payload: postID, timestamp: timeValue, key: dataSnapshot.key))
                                        
                                        rCount -= 1
                                        if rCount == 0 {
                                            if atomicCounter.decrementAndGet() == 0{
                                                self.finalizeList()
                                            }
                                        }
                                        
                                    }){ (error) in
                                        print(error.localizedDescription)
                                    }
                                }
                                
                            case "u":
                                let section = notificationType.value as! [String : [String : Int]]
                                
                                var uCount = section.count
                                if uCount == 0 {
                                    if atomicCounter.decrementAndGet() == 0 {
                                        self.finalizeList()
                                    }
                                }
                                
                                for child in section{
                                    let childKeySplit = child.key.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)
                                    let commentID = String(childKeySplit[0])
                                    var commentContent = String(childKeySplit[1].replacingOccurrences(of: "^", with: " "))
                                    let newHeartsCount = child.value.count
                                    
                                    if commentContent.count > 25 && commentContent[commentContent.count - 3 ... commentContent.count - 1] == "   " {
                                        commentContent = commentContent[0 ... commentContent.count - 4].trimmingCharacters(in: .whitespaces) + "..."
                                    }
                                    
                                    self.ref.child(self.userNotificationsPath+"u/"+child.key).queryOrderedByValue().queryLimited(toLast: 1).observeSingleEvent(of: .value, with: { (dataSnapshot) in
                                        
                                        let grandchildren = dataSnapshot.value as? [String : Int]
                                        for mostRecent in grandchildren! {
                                            let timeValue = mostRecent.value
                                            var body : String!
                                            if newHeartsCount == 1 {
                                                body = "You got \(newHeartsCount) Heart on a comment, \"" + commentContent + "\""
                                            }
                                            else {
                                                body = "You got \(newHeartsCount) Hearts on a comment, \"" + commentContent + "\""
                                            }
                                            
                                            self.notificationItems.append(NotificationItem(body: body, type: self.TYPE_U, payload: commentID, timestamp: timeValue, key: dataSnapshot.key))
                                            
                                            uCount -= 1
                                            if uCount == 0 {
                                                if atomicCounter.decrementAndGet() == 0 {
                                                    self.finalizeList()
                                                }
                                            }
                                        }
                                        
                                    }){ (error) in
                                        print(error.localizedDescription)
                                    }
                                }
                                
                            case "v":
                                let section = notificationType.value as! [String : [String : Int]]
                                
                                var vCount = section.count
                                if vCount == 0 {
                                    if atomicCounter.decrementAndGet() == 0 {
                                        self.finalizeList()
                                    }
                                }
                                
                                for child in section{
                                    let childKeySplit = child.key.split(separator: ":", maxSplits: 3, omittingEmptySubsequences: true)
                                    let postID = String(childKeySplit[0])
                                    let redName = String(childKeySplit[1].replacingOccurrences(of: "^", with: " "))
                                    let blueName = String(childKeySplit[2].replacingOccurrences(of: "^", with: " "))
                                    let question = String(childKeySplit[3].replacingOccurrences(of: "^", with: " "))
                                    let newVotesCount = child.value.count
                                    
                                    self.ref.child(self.userNotificationsPath+"v/"+child.key).queryOrderedByValue().queryLimited(toLast: 1).observeSingleEvent(of: .value, with: { (dataSnapshot) in
                                        
                                        let grandchildren = dataSnapshot.value as? [String : Int]
                                        for mostRecent in grandchildren! {
                                            let timeValue = mostRecent.value
                                            var body : String!
                                            if newVotesCount == 1 {
                                                body = "You got \(newVotesCount) New Vote on your post\n" + question + "\n\"" + redName + " vs. " + blueName + "\""
                                            }
                                            else {
                                                body = "You got \(newVotesCount) New Votes on your post\n" + question + "\n\"" + redName + " vs. " + blueName + "\""
                                            }
                                            
                                            self.notificationItems.append(NotificationItem(body: body, type: self.TYPE_V, payload: postID, timestamp: timeValue, key: dataSnapshot.key))
                                            
                                            vCount -= 1
                                            if vCount == 0 {
                                                if atomicCounter.decrementAndGet() == 0 {
                                                    self.finalizeList()
                                                }
                                            }
                                        }
                                        
                                    }){ (error) in
                                        print(error.localizedDescription)
                                    }
                                }
                                
                            case "em":
                                let payloadContent = "Click here to add an email address for account recovery in case you forget your password.\nYou can also add or change it later in Settings (located at the top right of Me page)."
                                self.notificationItems.append(NotificationItem(body: payloadContent, type: self.TYPE_EM, timestamp: Int(NSDate().timeIntervalSince1970)))
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
