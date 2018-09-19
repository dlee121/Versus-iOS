//
//  NotificationsViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/13/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import Firebase
import PopupDialog

class NotificationsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NotificationsDelegator {

    @IBOutlet weak var tableView: UITableView!
    var emailSetUpButtonLock = false
    
    var notificationItems : [NotificationItem]!
    var userNotificationsPath, nrtPath : String!
    var ref : DatabaseReference!
    var initialLoadLock = false
    var initialLoaderHandle : UInt!
    var currentUsername : String!
    var fList = [String]()
    
    let TYPE_U = 0 //new comment upvote notification
    let TYPE_C = 1 //new comment reply notification
    let TYPE_V = 2 //new post vote notification
    let TYPE_R = 3 //new post root comment notification
    let TYPE_F = 4 //new follower notification
    let TYPE_M = 5 //new medal notification
    let TYPE_EM = 6 //for password reset email setup notification
    
    var segueType = 0
    
    let postSegue = 0
    let rootSegue = 1
    let childSegue = 2
    let grandchildSegue = 3
    let followerSegue = 4
    let emailSegue = 5
    
    var seguePostID : String?
    var segueComment, segueTopCardComment : VSComment?
    var seguePost : PostObject?
    var segueUserAction : UserAction?
    
    var notificationClickLock = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        notificationItems = [NotificationItem]()
        navigationItem.title = "Notifications"
        tableView.separatorStyle = .none
        currentUsername = UserDefaults.standard.string(forKey: "KEY_USERNAME")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        notificationClickLock = false
        notificationItems.removeAll()
        initialLoadLock = false
        ref = Database.database().reference()
        
        userNotificationsPath = getUsernameHash(username: currentUsername!)+"/"+currentUsername!+"/n/"
        nrtPath = getUsernameHash(username: currentUsername!)+"/"+currentUsername!+"/nrt/"
        initialLoaderHandle = ref.child(userNotificationsPath).observe(DataEventType.value, with: { (snapshot) in
            if !self.initialLoadLock {
                self.initialLoadLock = true
                if let value = snapshot.value as? [String : AnyObject] {
                    let atomicCounter = AtomicInteger(value: value.count)
                    for notificationType in value { //notificationType = notificationTypeKey : [notificationKey : [Username : TimeValue]]
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
                                    
                                    let enumerator = dataSnapshot.children
                                    while let grandchild = enumerator.nextObject() as? DataSnapshot {
                                        usernames.append(grandchild.key + ", ")
                                        i -= 1
                                        if i == 0 {
                                            timeValue = grandchild.value as! Int
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
                                
                                let enumerator = dataSnapshot.children
                                while let grandchild = enumerator.nextObject() as? DataSnapshot {
                                    usernames.append(grandchild.key + ", ")
                                    i -= 1
                                    if i == 0 {
                                        timeValue = grandchild.value as! Int
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
                                    header = "Congratulations!\nYou won a Gold Medal for,"
                                case "s":
                                    header = "Congratulations!\nYou won a Silver Medal for,"
                                case "b":
                                    header = "Congratulations!\nYou won a Bronze Medal for,"
                                default:
                                    header = "Congratulations!\nYou won a medal for,"
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
                                    
                                    let enumerator = dataSnapshot.children
                                    while let grandchild = enumerator.nextObject() as? DataSnapshot {
                                        usernames.append(grandchild.key + ", ")
                                        i -= 1
                                        if i == 0 {
                                            timeValue = grandchild.value as! Int
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
            else {
                print("hohohoho")
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
        emailSetUpButtonLock = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        notificationClickLock = false
        ref.child(userNotificationsPath).removeObserver(withHandle: initialLoaderHandle)
    }

    func finalizeList() {
        
        notificationItems.sort(by: >)
        
        tableView.reloadData()
        
        ref.child(nrtPath).setValue(Int(NSDate().timeIntervalSince1970))
        tabBarController?.tabBar.items?[3].badgeValue = nil
        (tabBarController as? TabBarViewController)?.setBadge = false
    }
    

    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        print("didReceiveMemoryWarning")
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
        cell!.setCell(item: notificationItems[indexPath.row], row: indexPath.row)
        cell!.delegate = self
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !notificationClickLock {
            notificationClickLock = true
            let item = notificationItems[indexPath.row]
            switch item.type {
            case TYPE_C:
                goToComment(commentID: item.payload!)
            case TYPE_F:
                segueType = followerSegue
                goToFollowersPage()
            case TYPE_M:
                goToComment(commentID: item.payload!)
            case TYPE_R:
                segueType = postSegue
                seguePostID = item.payload!
                performSegue(withIdentifier: "notificationsToRoot", sender: self)
            case TYPE_U:
                goToComment(commentID: item.payload!)
            case TYPE_V:
                segueType = postSegue
                seguePostID = item.payload!
                performSegue(withIdentifier: "notificationsToRoot", sender: self)
            case TYPE_EM:
                CFRunLoopWakeUp(CFRunLoopGetCurrent())
                showCustomDialog()
                break
            default:
                break
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func goToComment(commentID : String) {
        VSVersusAPIClient.default().commentGet(a: "c", b: commentID).continueWith(block:) {(task: AWSTask) -> AnyObject? in
            
            if task.error != nil {
                DispatchQueue.main.async {
                    print(task.error!)
                }
            }
            else {
                if let result = task.result {
                    self.segueComment = VSComment(itemSource: result.source!, id: result.id!)
                    VSVersusAPIClient.default().postGet(a: "p", b: self.segueComment!.post_id).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                        
                        if task.error != nil {
                            DispatchQueue.main.async {
                                print(task.error!)
                            }
                        }
                        else {
                            if let result = task.result {
                                self.seguePost = PostObject(itemSource: result.source!, id: result.id!)
                                
                                
                                let userActionID = self.currentUsername + self.seguePost!.post_id
                                
                                VSVersusAPIClient.default().recordGet(a: "rcg", b: userActionID).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                                    
                                    if task.error != nil {
                                        self.segueUserAction = UserAction(idIn: userActionID)
                                    }
                                    else {
                                        if let result = task.result {
                                            self.segueUserAction = UserAction(itemSource: result, idIn: userActionID)
                                        }
                                        else {
                                            self.segueUserAction = UserAction(idIn: userActionID)
                                        }
                                    }
                                    
                                    if self.segueComment!.root == "0" {
                                        if self.segueComment!.post_id == self.segueComment!.parent_id {
                                            //root comment
                                            self.segueComment!.nestedLevel = 0
                                            self.segueType = self.rootSegue
                                            DispatchQueue.main.async {
                                                self.performSegue(withIdentifier: "notificationsToRoot", sender: self)
                                            }
                                        }
                                        else {
                                            //child comment
                                            self.segueComment!.nestedLevel = 3
                                            self.segueType = self.childSegue
                                            VSVersusAPIClient.default().commentGet(a: "c", b: self.segueComment!.parent_id).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                                                
                                                if task.error != nil {
                                                    self.segueUserAction = UserAction(idIn: userActionID)
                                                }
                                                else {
                                                    if let result = task.result {
                                                        self.segueTopCardComment = VSComment(itemSource: result.source!, id: result.id!)
                                                        DispatchQueue.main.async {
                                                            self.performSegue(withIdentifier: "notificationsToChild", sender: self)
                                                        }
                                                    }
                                                }
                                                return nil
                                            }
                                        }
                                    }
                                    else {
                                        //grandchild comment
                                        self.segueComment!.nestedLevel = 5
                                        self.segueType = self.grandchildSegue
                                        VSVersusAPIClient.default().commentGet(a: "c", b: self.segueComment!.parent_id).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                                            
                                            if task.error != nil {
                                                self.segueUserAction = UserAction(idIn: userActionID)
                                            }
                                            else {
                                                if let result = task.result {
                                                    self.segueTopCardComment = VSComment(itemSource: result.source!, id: result.id!)
                                                    DispatchQueue.main.async {
                                                        self.performSegue(withIdentifier: "notificationsToGrandchild", sender: self)
                                                    }
                                                }
                                            }
                                            return nil
                                        }
                                    }
                                    
                                    
                                    return nil
                                }
                            }
                        }
                        return nil
                    }
                    
                    
                    
                    
                }
            }
            return nil
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueType {
        case postSegue:
            guard let rootVC = segue.destination as? RootPageViewController else {return}
            let view = rootVC.view //necessary for loading the view
            let userActionID = currentUsername+seguePostID!
            
            VSVersusAPIClient.default().postGet(a: "p", b: seguePostID!).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                if task.error != nil {
                    DispatchQueue.main.async {
                        print(task.error!)
                    }
                }
                else {
                    if let postResult = task.result {
                        
                        let postObject = PostObject(itemSource: postResult.source!, id: postResult.id!)
                        
                        VSVersusAPIClient.default().pivsingleGet(a: "pi", b: postObject.author).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                            
                            if task.error != nil {
                                DispatchQueue.main.async {
                                    print(task.error!)
                                }
                            }
                            else {
                                if let result = task.result {
                                    postObject.profileImageVersion = result.pi!.intValue
                                }
                            }
                            return nil
                        }
                        
                        VSVersusAPIClient.default().recordGet(a: "rcg", b: userActionID).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                            
                            if task.error != nil {
                                rootVC.setUpRootPage(post: postObject, userAction: UserAction(idIn: userActionID), fromCreatePost: false)
                            }
                            else {
                                if let result = task.result {
                                    rootVC.setUpRootPage(post: postObject, userAction: UserAction(itemSource: result, idIn: userActionID), fromCreatePost: false)
                                }
                                else {
                                    rootVC.setUpRootPage(post: postObject, userAction: UserAction(idIn: userActionID), fromCreatePost: false)
                                }
                            }
                            return nil
                        }
                    }
                }
                return nil
            }
            
        case rootSegue:
            guard let rootVC = segue.destination as? RootPageViewController else {return}
            let view = rootVC.view //necessary for loading the view
            rootVC.commentClickSetUpRootPage(post: seguePost!, userAction: segueUserAction!, topicComment: segueComment!)
            
        case childSegue:
            guard let childVC = segue.destination as? ChildPageViewController else {return}
            let view = childVC.view //necessary for loading the view
            childVC.commentClickSetUpChildPage(post: seguePost!, comment: segueTopCardComment!, userAction: segueUserAction!, topicComment: segueComment!)
            
        case grandchildSegue:
            guard let gcVC = segue.destination as? GrandchildPageViewController else {return}
            let view = gcVC.view //necessary for loading the view
            gcVC.commentClickSetUpGrandchildPage(post: seguePost!, comment: segueTopCardComment!, userAction: segueUserAction!, topicComment: segueComment!)
            
        case followerSegue:
            /*
            let backItem = UIBarButtonItem()
            backItem.title = currentUsername
            navigationItem.backBarButtonItem = backItem
            */
            guard let fghVC = segue.destination as? FGHViewController else {return}
            let view = fghVC.view //necessary for loading the view
            fghVC.fORg = 0
            print("fList size = \(fList.count)")
            fghVC.setUpFPage(followers: fList)
            
            break
        case emailSegue:
            break
        default:
            break
        }
    }
    
    func goToFollowersPage(){
        fList.removeAll()
        
        let userPath = getUsernameHash(username: currentUsername) + "/" + currentUsername
        let fPath = userPath + "/f"
        let hPath = userPath + "/h"
        ref.child(hPath).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let enumerator = snapshot.children
            while let item = enumerator.nextObject() as? DataSnapshot {
                self.fList.append(item.key)
            }
            
            
            self.ref.child(fPath).observeSingleEvent(of: .value, with: { (snapshot) in
                
                let enumerator = snapshot.children
                while let item = enumerator.nextObject() as? DataSnapshot {
                    self.fList.append(item.key)
                }
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "notificationsToFGH", sender: self)
                }
                
            }) { (error) in
                print(error.localizedDescription)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
        
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
                        var credential = EmailAuthProvider.credential(withEmail: self.currentUsername + "@versusbcd.com", password: emailSetupVC.emPwIn.text!)
                        
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
                                            //remove the Type_EM item from local list and firebase
                                            self.notificationItems.remove(at: 0)
                                            self.tableView.reloadData()
                                        }
                                        UserDefaults.standard.set(emailInput, forKey: "KEY_EMAIL")
                                        self.ref.child(self.userNotificationsPath+"em").removeValue() //remove the email setup notification in firebase
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
    
    func closeNotification(subpath: String, row: Int) {
        print(subpath)
        ref.child(userNotificationsPath+subpath).removeValue()
        notificationItems.remove(at: row)
        tableView.reloadData() //gotta reload to update rowNumber on all cells
    }

}
