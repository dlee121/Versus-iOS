//
//  TabBarViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 8/15/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseMessaging

class TabBarViewController: UITabBarController {

    let button = UIButton.init(type: .custom)
    var previousTabNum = 0
    var observer: NSObjectProtocol!
    var ref : DatabaseReference = Database.database().reference()
    var currentUsername, userNotificationsPath, nrtPath : String!
    var observerHandle : UInt!
    var setBadge = false
    var notificationsTab : NotificationsViewController?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        addCenterButton(withImage: #imageLiteral(resourceName: "main_fab"), highlightImage: #imageLiteral(resourceName: "main_fab"))
        addNotificationObserver()
        
        Messaging.messaging().subscribe(toTopic: currentUsername)
    }
    
    
    deinit {
        ref.child(userNotificationsPath).removeObserver(withHandle: observerHandle)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("tab bar appear")
    }
    
    func addNotificationObserver() {
        currentUsername = UserDefaults.standard.string(forKey: "KEY_USERNAME")
        userNotificationsPath = getUsernameHash(username: currentUsername!)+"/"+currentUsername!+"/n/"
        nrtPath = getUsernameHash(username: currentUsername!)+"/"+currentUsername!+"/nrt/"
        var notificationTimes = [Int]()
        
        if observerHandle != nil {
            ref.child(userNotificationsPath).removeObserver(withHandle: observerHandle)
        }
        
        observerHandle = self.ref.child(self.userNotificationsPath).observe(DataEventType.value, with: { (snapshot) in
            let group = DispatchGroup()
            
            if let value = snapshot.value as? [String : AnyObject] {
                
                self.ref.child(self.nrtPath).observeSingleEvent(of: .value, with: { (snapshot) in
                    
                    if let notificationReadTime = snapshot.value as? Int {
                        for notificationType in value { //notificationType = notificationTypeKey : [notificationKey : [Username : TimeValue]]
                            switch notificationType.key {
                            case "c":
                                let section = notificationType.value as! [String : [String : Int]]
                                
                                for child in section{
                                    group.enter()
                                    self.ref.child(self.userNotificationsPath+"c/"+child.key).queryOrderedByValue().queryLimited(toLast: 1).observeSingleEvent(of: .value, with: { (dataSnapshot) in
                                        let grandchildren = dataSnapshot.value as? [String : Int]
                                        for grandchild in grandchildren! {
                                            notificationTimes.append(grandchild.value)
                                        }
                                        group.leave()
                                    }){ (error) in
                                        print(error.localizedDescription)
                                    }
                                }
                                
                                
                            case "f":
                                group.enter()
                                self.ref.child(self.userNotificationsPath+"f/").queryOrderedByValue().queryLimited(toLast: 1).observeSingleEvent(of: .value, with: { (dataSnapshot) in
                                    let grandchildren = dataSnapshot.value as? [String : Int]
                                    for grandchild in grandchildren! {
                                        notificationTimes.append(grandchild.value)
                                    }
                                    group.leave()
                                    
                                }){ (error) in
                                    print(error.localizedDescription)
                                }
                                
                            case "m":
                                let section = notificationType.value as! [String : String]
                                for child in section {
                                    let childKeySplit = child.value.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: true)
                                    notificationTimes.append(Int(childKeySplit[1])!)
                                }
                                
                            case "r":
                                let section = notificationType.value as! [String : [String : Int]]
                                
                                for child in section{
                                    group.enter()
                                    self.ref.child(self.userNotificationsPath+"r/"+child.key).queryOrderedByValue().queryLimited(toLast: 1).observeSingleEvent(of: .value, with: { (dataSnapshot) in
                                        let grandchildren = dataSnapshot.value as? [String : Int]
                                        for grandchild in grandchildren! {
                                            notificationTimes.append(grandchild.value)
                                        }
                                        group.leave()
                                    }){ (error) in
                                        print(error.localizedDescription)
                                    }
                                }
                                
                            case "u":
                                let section = notificationType.value as! [String : [String : Int]]
                                
                                for child in section{
                                    group.enter()
                                    self.ref.child(self.userNotificationsPath+"u/"+child.key).queryOrderedByValue().queryLimited(toLast: 1).observeSingleEvent(of: .value, with: { (dataSnapshot) in
                                        
                                        let grandchildren = dataSnapshot.value as? [String : Int]
                                        for mostRecent in grandchildren! {
                                            notificationTimes.append(mostRecent.value)
                                        }
                                        group.leave()
                                    }){ (error) in
                                        print(error.localizedDescription)
                                    }
                                }
                                
                            case "v":
                                let section = notificationType.value as! [String : [String : Int]]
                                
                                for child in section{
                                    group.enter()
                                    self.ref.child(self.userNotificationsPath+"v/"+child.key).queryOrderedByValue().queryLimited(toLast: 1).observeSingleEvent(of: .value, with: { (dataSnapshot) in
                                        
                                        let grandchildren = dataSnapshot.value as? [String : Int]
                                        for mostRecent in grandchildren! {
                                            notificationTimes.append(mostRecent.value)
                                        }
                                        group.leave()
                                    }){ (error) in
                                        print(error.localizedDescription)
                                    }
                                }
                                
                            default:
                                break
                                
                            }
                            
                        }
                        
                        group.notify(queue: .main) {
                            notificationTimes.sort(by: >)
                            if notificationTimes.count > 0 && notificationTimes[0] > notificationReadTime{
                                
                                print("we got new notifications!, \(notificationTimes[0]) > \(notificationReadTime), \(notificationTimes.count) items")
                                
                                DispatchQueue.main.async {
                                    if self.selectedIndex != 3 {
                                        self.tabBar.items?[3].badgeValue = "New"
                                    }
                                    self.setBadge = true
                                }
                            }
                            else {
                                //no new notifications
                            }
                            notificationTimes.removeAll()
                        }
                        
                    }
                    else {
                        self.ref.child(self.nrtPath).setValue(Int(NSDate().timeIntervalSince1970))
                    }
                }){ (error) in
                    print(error.localizedDescription)
                }
            }
            
        }){ (error) in
            print(error.localizedDescription)
        }
        
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("tab bar disappear")
        
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        //necessary in case user taps the actual middle tap element exposed below the center button instead of tapping the center button
        previousTabNum = selectedIndex
        
        if previousTabNum == 3 && setBadge{ //exiting notifications tab
            print("exiting notifications, setting badge again")
            self.tabBar.items?[3].badgeValue = "New" //in case a new notification arrived while user was in the notifications page
        }
    }
    
    
    
    func createPostBack(){
        selectedIndex = previousTabNum
        tabBar.isHidden = false
    }
    
    @objc
    func handleTouchTabbarCenter(sender : UIButton)
    {
        if let count = self.tabBar.items?.count
        {
            let i = floor(Double(count / 2))
            previousTabNum = selectedIndex
            self.selectedViewController = self.viewControllers?[Int(i)]
        }
    }
    
    func addCenterButton(withImage buttonImage : UIImage, highlightImage: UIImage) {
        
        let paddingBottom : CGFloat = 10.0
        let diameter : CGFloat = 58
        
        button.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin, .flexibleLeftMargin, .flexibleBottomMargin]
        button.frame = CGRect(x: 0.0, y: 0.0, width: diameter, height: diameter)
        button.setBackgroundImage(buttonImage, for: .normal)
        button.setBackgroundImage(highlightImage, for: .highlighted)
        
        let rectBoundTabbar = self.tabBar.bounds
        let xx = rectBoundTabbar.midX
        let yy = rectBoundTabbar.midY - paddingBottom
        button.center = CGPoint(x: xx, y: yy)
        
        self.tabBar.addSubview(button)
        self.tabBar.bringSubview(toFront: button)
        (self.tabBar as! CustomTabBar).middleButton = button
        (self.tabBar as! CustomTabBar).radius = diameter/2
        
        button.addTarget(self, action: #selector(handleTouchTabbarCenter), for: .touchUpInside)
        
        if let count = self.tabBar.items?.count
        {
            let i = floor(Double(count / 2))
            let item = self.tabBar.items![Int(i)]
            item.title = ""
        }
    }

    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // safe place to set the frame of button manually
        //button.frame = CGRect.init(x: self.tabBar.center.x - 32, y: self.view.bounds.height - 74, width: 64, height: 64)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

