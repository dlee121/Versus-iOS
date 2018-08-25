//
//  MeViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/13/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import Firebase
import AWSS3
import Nuke

class ProfileViewController: ButtonBarPagerTabStripViewController {
    
    
    @IBOutlet weak var followers: UIButton!
    @IBOutlet weak var followings: UIButton!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var influence: UILabel!
    @IBOutlet weak var goldMedals: UILabel!
    @IBOutlet weak var silverMedals: UILabel!
    @IBOutlet weak var bronzeMedals: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var fghIcon: UIImageView!
    @IBOutlet weak var containerViewBottom: NSLayoutConstraint!
    
    var currentUsername : String!
    var fList = [String]()
    var gList = [String]()
    var hList = [String]()
    var ref: DatabaseReference!
    
    var followingThisUser = "0" //0 by default, f if this is my follower, g if I'm following them, and h if both
    
    var fgcp = 0 //0 = f, 1 = g, c = 2, p = 3
    let f = 0
    let g = 1
    let c = 2
    let p = 3
    
    var segueType = 0
    
    let postSegue = 0
    let rootSegue = 1
    let childSegue = 2
    let grandchildSegue = 3
    let followerSegue = 4
    
    var clickedComment, segueComment, segueTopComment : VSComment?
    var clickedPost, seguePost : PostObject?
    var segueUserAction : UserAction?
    
    var fromPostPage : Bool?
    
    let apiClient = VSVersusAPIClient.default()
    
    override func viewDidLoad() {
        self.loadDesign()
        super.viewDidLoad()
        
        ref = Database.database().reference()
        DispatchQueue.main.async {
            self.profileImage.layer.cornerRadius = self.profileImage.frame.size.height / 2
            self.profileImage.clipsToBounds = true
            self.followings.titleLabel?.textAlignment = NSTextAlignment.center
            self.followers.titleLabel?.textAlignment = NSTextAlignment.center
        }
        
        navigationItem.title = currentUsername
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        
        if fromPostPage != nil && fromPostPage! {
            containerViewBottom.constant = -tabBarController!.tabBar.frame.height
        }
    }
    
    override func viewWillAppear(_ animated: Bool){
        super.viewWillAppear(animated)
        
        if self.currentUsername == UserDefaults.standard.string(forKey: "KEY_USERNAME") {
            followButton.isHidden = true
        }
        else {
            followButton.isHidden = false
        }
        self.fghIcon.image = nil
        setupFGH()
        
        apiClient.profileinfoGet(a: "pim", b: currentUsername.lowercased()).continueWith(block:) {(task: AWSTask) -> AnyObject? in
            if task.error != nil {
                DispatchQueue.main.async {
                    print(task.error!)
                }
            }
            else {
                DispatchQueue.main.async {
                    let result = task.result!.source
                    self.influence.text = "\(result!._in!) influence"
                    self.goldMedals.text = "\(result!.g!)"
                    self.goldMedals.addImage(imageName: "medalGold", imageHeight: 24)
                    self.silverMedals.text = "\(result!.s!)"
                    self.silverMedals.addImage(imageName: "medalSilver", imageHeight: 24)
                    self.bronzeMedals.text = "\(result!.b!)"
                    self.bronzeMedals.addImage(imageName: "medalBronze", imageHeight: 24)
                    
                    let pi = result!.pi!.intValue
                    if(pi > 0){
                        self.setProfileImage(username: self.currentUsername, profileImageVersion: pi)
                    }
                    else{
                        self.profileImage.image = #imageLiteral(resourceName: "default_profile")
                    }
                    
                }
            }
            return nil
        }
        
    }
    
    func setUpFollowButton(){
        //check if we have a f/g/h relationship with this user
        DispatchQueue.main.async {
            switch self.followingThisUser {
            case "f":
                self.followButton.setTitle("Follow", for: .normal)
                self.fghIcon.image = #imageLiteral(resourceName: "profile_icon_f")
            case "g":
                self.followButton.setTitle("Followed", for: .normal)
                self.fghIcon.image = #imageLiteral(resourceName: "profile_icon_g")
            case "h":
                self.followButton.setTitle("Followed", for: .normal)
                self.fghIcon.image = #imageLiteral(resourceName: "profile_icon_h")
            default:
                self.followButton.setTitle("Follow", for: .normal)
                self.fghIcon.image = nil
            }
        }
    }
    
    
    func setupFGH(){
        fList.removeAll()
        gList.removeAll()
        hList.removeAll()
        
        var usernameHash : Int32
        if(currentUsername.count < 5){
            usernameHash = currentUsername.hashCode()
        }
        else{
            var hashIn = ""
            
            hashIn.append(currentUsername[0])
            hashIn.append(currentUsername[currentUsername.count-2])
            hashIn.append(currentUsername[1])
            hashIn.append(currentUsername[currentUsername.count-1])
            
            usernameHash = hashIn.hashCode()
        }
        
        let userPath = "\(usernameHash)/" + currentUsername
        let fPath = userPath + "/f"
        let gPath = userPath + "/g"
        let hPath = userPath + "/h"
        
        var loggedInUsername = UserDefaults.standard.string(forKey: "KEY_USERNAME")
        
        ref.child(hPath).observeSingleEvent(of: .value, with: { (snapshot) in
            self.followingThisUser = "0"
            
            let enumerator = snapshot.children
            while let item = enumerator.nextObject() as? DataSnapshot {
                if loggedInUsername == item.key {
                    self.followingThisUser = "h"
                    print("set to h")
                }
                self.hList.append(item.key)
            }
            
            self.ref.child(fPath).observeSingleEvent(of: .value, with: { (snapshot) in
                
                let enumerator = snapshot.children
                while let item = enumerator.nextObject() as? DataSnapshot {
                    if loggedInUsername == item.key {
                        self.followingThisUser = "g" //this is g, because being in their fList means the logged-in user is following this profile's user
                    }
                    self.fList.append(item.key)
                }
                self.setUpFollowButton()
                DispatchQueue.main.async {
                    self.followers.setTitle("\(self.fList.count + self.hList.count)\nFollowers", for: .normal)
                }
                
            }) { (error) in
                print(error.localizedDescription)
            }
            
            self.ref.child(gPath).observeSingleEvent(of: .value, with: { (snapshot) in
                
                let enumerator = snapshot.children
                while let item = enumerator.nextObject() as? DataSnapshot {
                    if loggedInUsername == item.key {
                        self.followingThisUser = "f" //this is f, because being in their gList means this profile's user is following the logged-in user
                    }
                    self.gList.append(item.key)
                }
                self.setUpFollowButton()
                DispatchQueue.main.async {
                    self.followings.setTitle("\(self.gList.count + self.hList.count)\nFollowing", for: .normal)
                }
                
            }) { (error) in
                print(error.localizedDescription)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let child_1 = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CommentsHistory")
        let child_2 = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PostsHistory")
        let view = child_2.view
        (child_1 as! CommentsHistoryViewController).setUpCommentsHistory(username: currentUsername, thisIsMe: false)
        (child_2 as! PostsHistoryViewController).setUpPostsHistory(username: currentUsername, thisIsMe: false)
        return [child_1, child_2]
    }
    
    
    
    func loadDesign() {
        //self.settings.style.buttonBarHeight = 325.0
        self.settings.style.buttonBarBackgroundColor = UIColor(red: 0.970, green: 0.970, blue: 0.970, alpha: 1)
        self.settings.style.buttonBarItemBackgroundColor = UIColor(red: 0.970, green: 0.970, blue: 0.970, alpha: 1) //255*0.949=242 but this actually equals 239 on storyboard
        self.settings.style.selectedBarBackgroundColor = UIColor(named: "VS_Red")!
        self.settings.style.buttonBarItemFont = .boldSystemFont(ofSize: 16)
        self.settings.style.selectedBarHeight = 1.5
        self.settings.style.buttonBarMinimumLineSpacing = 0
        self.settings.style.buttonBarItemTitleColor = UIColor(named: "VS_Red")
        self.settings.style.buttonBarItemsShouldFillAvailableWidth = true
        self.settings.style.buttonBarLeftContentInset = 0
        self.settings.style.buttonBarRightContentInset = 0
        
        changeCurrentIndexProgressive = { (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in guard changeCurrentIndex == true else { return }
            oldCell?.label.textColor = UIColor(red: 0.502, green: 0.502, blue: 0.502, alpha: 1)
            newCell?.label.textColor = UIColor(named: "VS_Red")
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
    
    func setProfileImage(username : String, profileImageVersion : Int){
        let request = AWSS3GetPreSignedURLRequest()
        request.expires = Date().addingTimeInterval(86400)
        request.bucket = "versus.profile-pictures"
        request.httpMethod = .GET
        request.key = username + "-\(profileImageVersion).jpeg"
        
        AWSS3PreSignedURLBuilder.default().getPreSignedURL(request).continueWith { (task:AWSTask<NSURL>) -> Any? in
            if let error = task.error {
                print("Error: \(error)")
                return nil
            }
            
            let presignedURL = task.result
            DispatchQueue.main.async {
                Nuke.loadImage(with: presignedURL!.absoluteURL!, into: self.profileImage)
            }
            
            return nil
        }
        
    }
    
    @IBAction func followersTapped(_ sender: UIButton) {
        fgcp = f
        performSegue(withIdentifier: "profileToFGH", sender: self)
    }
    
    @IBAction func followingsTapped(_ sender: UIButton) {
        fgcp = g
        performSegue(withIdentifier: "profileToFGH", sender: self)
    }
    
    func handleCommentsHistoryClick(comment : VSComment){
        fgcp = c
        clickedComment = comment
        
        goToComment(commentID: comment.comment_id)
    }
    
    func handlePostsHistoryClick(post : PostObject){
        fgcp = p
        clickedPost = post
        performSegue(withIdentifier: "profileToRoot", sender: self)
    }
    
    func goToComment(commentID : String) {
        self.apiClient.commentGet(a: "c", b: commentID).continueWith(block:) {(task: AWSTask) -> AnyObject? in
            
            if task.error != nil {
                DispatchQueue.main.async {
                    print(task.error!)
                }
            }
            else {
                if let result = task.result {
                    self.segueComment = VSComment(itemSource: result.source!, id: result.id!)
                    self.apiClient.postGet(a: "p", b: self.segueComment!.post_id).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                        
                        if task.error != nil {
                            DispatchQueue.main.async {
                                print(task.error!)
                            }
                        }
                        else {
                            if let result = task.result {
                                self.seguePost = PostObject(itemSource: result.source!, id: result.id!)
                                
                                
                                let userActionID = self.currentUsername + self.seguePost!.post_id
                                
                                self.apiClient.recordGet(a: "rcg", b: userActionID).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                                    
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
                                                self.performSegue(withIdentifier: "profileToRoot", sender: self)
                                            }
                                        }
                                        else {
                                            //child comment
                                            self.segueComment!.nestedLevel = 3
                                            self.segueType = self.childSegue
                                            self.apiClient.commentGet(a: "c", b: self.segueComment!.parent_id).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                                                
                                                if task.error != nil {
                                                    self.segueUserAction = UserAction(idIn: userActionID)
                                                }
                                                else {
                                                    if let result = task.result {
                                                        self.segueTopComment = VSComment(itemSource: result.source!, id: result.id!)
                                                        DispatchQueue.main.async {
                                                            self.performSegue(withIdentifier: "profileToChild", sender: self)
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
                                        self.apiClient.commentGet(a: "c", b: self.segueComment!.parent_id).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                                            
                                            if task.error != nil {
                                                self.segueUserAction = UserAction(idIn: userActionID)
                                            }
                                            else {
                                                if let result = task.result {
                                                    self.segueTopComment = VSComment(itemSource: result.source!, id: result.id!)
                                                    DispatchQueue.main.async {
                                                        self.performSegue(withIdentifier: "profileToGrandchild", sender: self)
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
        
        
        switch fgcp {
        case f:
            let backItem = UIBarButtonItem()
            backItem.title = currentUsername
            navigationItem.backBarButtonItem = backItem
            
            guard let fghVC = segue.destination as? FGHViewController else {return}
            let view = fghVC.view //necessary for loading the view
            fghVC.fORg = fgcp
            fghVC.setUpFPage(followers: combineLists(list1: hList, list2: fList))
        case g:
            let backItem = UIBarButtonItem()
            backItem.title = currentUsername
            navigationItem.backBarButtonItem = backItem
            
            guard let fghVC = segue.destination as? FGHViewController else {return}
            let view = fghVC.view //necessary for loading the view
            fghVC.fORg = fgcp
            fghVC.setUpFPage(followers: combineLists(list1: hList, list2: gList))
        case c:
            let backItem = UIBarButtonItem()
            backItem.title = "Back"
            navigationItem.backBarButtonItem = backItem
            //set up comments history item click segue
            switch segueType {
            case rootSegue:
                guard let rootVC = segue.destination as? RootPageViewController else {return}
                let view = rootVC.view //necessary for loading the view
                rootVC.commentClickSetUpRootPage(post: seguePost!, userAction: segueUserAction!, topicComment: segueComment!)
                
            case childSegue:
                guard let childVC = segue.destination as? ChildPageViewController else {return}
                let view = childVC.view //necessary for loading the view
                childVC.commentClickSetUpChildPage(post: seguePost!, comment: segueTopComment!, userAction: segueUserAction!, topicComment: segueComment!)
                
            case grandchildSegue:
                guard let gcVC = segue.destination as? GrandchildPageViewController else {return}
                let view = gcVC.view //necessary for loading the view
                gcVC.commentClickSetUpGrandchildPage(post: seguePost!, comment: segueTopComment!, userAction: segueUserAction!, topicComment: segueComment!)
            default:
                break
            }
            
        case p:
            let backItem = UIBarButtonItem()
            backItem.title = currentUsername
            navigationItem.backBarButtonItem = backItem
            
            guard let rootVC = segue.destination as? RootPageViewController else {return}
            let view = rootVC.view //necessary for loading the view
            let userActionID = UserDefaults.standard.string(forKey: "KEY_USERNAME")!+clickedPost!.post_id
            
            //set up posts history item click segue
            apiClient.postGet(a: "p", b: clickedPost!.post_id).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                if task.error != nil {
                    DispatchQueue.main.async {
                        print(task.error!)
                    }
                }
                else {
                    if let postResult = task.result {
                        var postObject = PostObject(itemSource: postResult.source!, id: postResult.id!)
                        self.apiClient.recordGet(a: "rcg", b: userActionID).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                            if task.error != nil {
                                rootVC.setUpRootPage(post: postObject, userAction: UserAction(idIn: userActionID), fromCreatePost: false)
                            }
                            else {
                                if let recordResult = task.result {
                                    rootVC.setUpRootPage(post: postObject, userAction: UserAction(itemSource: recordResult, idIn: userActionID), fromCreatePost: false)
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
            
            return
        default:
            return
        }
        
    }
    
    func combineLists(list1 : [String], list2 : [String]) -> [String] {
        
        if list1.count == 0 {
            if list2.count == 0 {
                return []
            }
            else {
                return list2
            }
        }
        else if list2.count == 0 {
            return list1
        }
        
        var combinedList = list1 + list2
        var index : Int
        var value : String
        
        for i in 1...combinedList.count-1 {
            value = combinedList[i]
            index = i
            while index > 0 && combinedList[index-1].lowercased() > value.lowercased() {
                index -= 1
            }
            
            combinedList.remove(at: i)
            combinedList.insert(value, at: index)
            
        }
        
        return combinedList
        
    }
    
    @IBAction func followButtonTapped(_ sender: UIButton) {
        var usernameHash : Int32
        if(currentUsername.count < 5){
            usernameHash = currentUsername.hashCode()
        }
        else{
            var hashIn = ""
            
            hashIn.append(currentUsername[0])
            hashIn.append(currentUsername[currentUsername.count-2])
            hashIn.append(currentUsername[1])
            hashIn.append(currentUsername[currentUsername.count-1])
            
            usernameHash = hashIn.hashCode()
        }
        
        let userPath = "\(usernameHash)/" + currentUsername
        let fPath = userPath + "/f"
        let gPath = userPath + "/g"
        let hPath = userPath + "/h"
        let contactsPath = userPath + "/contacts"
        var notificationPath = userPath + "/n/f"
        
        if let loggedInUsername = UserDefaults.standard.string(forKey: "KEY_USERNAME") {
            var myUsernameHash : Int32
            if(loggedInUsername.count < 5){
                myUsernameHash = loggedInUsername.hashCode()
            }
            else{
                var hashIn = ""
                
                hashIn.append(loggedInUsername[0])
                hashIn.append(loggedInUsername[loggedInUsername.count-2])
                hashIn.append(loggedInUsername[1])
                hashIn.append(loggedInUsername[loggedInUsername.count-1])
                
                myUsernameHash = hashIn.hashCode()
            }
            
            let myUserPath = "\(myUsernameHash)/" + loggedInUsername
            let myFPath = myUserPath + "/f"
            let myGPath = myUserPath + "/g"
            let myHPath = myUserPath + "/h"
            let myContactsPath = myUserPath + "/contacts"
            
            switch followingThisUser {
            case "f":
                //remove their username from your f list
                ref.child(myFPath+"/\(currentUsername!)").removeValue()
                //remove your username from their g list
                ref.child(gPath+"/\(loggedInUsername)").removeValue()
                //add your username to their h list
                ref.child(hPath+"/\(loggedInUsername)").setValue(true)
                //add their username to your h list
                ref.child(myHPath+"/\(currentUsername!)").setValue(true)
                
                //update local lists
                if let gIndex = binarySearch(inputArr: gList, searchItem: loggedInUsername) {
                    gList.remove(at: gIndex)
                }
                
                if hList.count > 0 {
                    for i in 0...hList.count-1 {
                        if(hList[i] >= loggedInUsername){
                            hList.insert(loggedInUsername, at: i)
                            break
                        }
                        else if i == hList.count-1 {
                            hList.insert(loggedInUsername, at: hList.count-1)
                            break
                        }
                    }
                }
                else {
                    hList.append(loggedInUsername)
                }
                
                followingThisUser = "h"
                DispatchQueue.main.async {
                    self.followers.setTitle("\(self.fList.count + self.hList.count)\nFollowers", for: .normal)
                    self.fghIcon.image = #imageLiteral(resourceName: "profile_icon_h")
                    self.followButton.setTitle("Followed", for: .normal)
                }
                
                //send follow notification to the profile user
                ref.child(notificationPath+"/\(loggedInUsername)").setValue(Int(NSDate().timeIntervalSince1970)) //set value as timestamp as seconds from epoch
                
            case "g":
                //remove their username from your g list
                ref.child(myGPath+"/\(currentUsername!)").removeValue()
                //remove your username from their f list
                ref.child(fPath+"/\(loggedInUsername)").removeValue()
                //remove their username from your contacts
                ref.child(myContactsPath+"/\(currentUsername!)").removeValue()
                //remove your username from their contacts
                ref.child(contactsPath+"/\(loggedInUsername)").removeValue()
                
                //update local lists
                if let fIndex = binarySearch(inputArr: fList, searchItem: loggedInUsername) {
                    fList.remove(at: fIndex)
                }
                
                followingThisUser = "0"
                
                DispatchQueue.main.async {
                    self.followers.setTitle("\(self.fList.count + self.hList.count)\nFollowers", for: .normal)
                    self.fghIcon.image = nil
                    self.followButton.setTitle("Follow", for: .normal)
                }
                
            case "h":
                //remove your username from their h list
                ref.child(hPath+"/\(loggedInUsername)").removeValue()
                //remove their username from your h list
                ref.child(myHPath+"/\(currentUsername!)").removeValue()
                //add their username to your f list
                ref.child(myFPath+"/\(currentUsername!)").setValue(true)
                //add your username to their g list
                ref.child(gPath+"/\(loggedInUsername)").setValue(true)
                
                //update local lists
                if let hIndex = binarySearch(inputArr: hList, searchItem: loggedInUsername) {
                    hList.remove(at: hIndex)
                }
                
                if gList.count > 0 {
                    for i in 0...gList.count-1 {
                        if(gList[i] >= loggedInUsername){
                            gList.insert(loggedInUsername, at: i)
                            break
                        }
                        else if i == gList.count-1 {
                            gList.insert(loggedInUsername, at: gList.count-1)
                            break
                        }
                    }
                }
                else {
                    gList.append(loggedInUsername)
                }
                
                
                followingThisUser = "f"
                DispatchQueue.main.async {
                    self.followers.setTitle("\(self.fList.count + self.hList.count)\nFollowers", for: .normal)
                    self.fghIcon.image = #imageLiteral(resourceName: "profile_icon_f")
                    self.followButton.setTitle("Follow", for: .normal)
                }
                
            default:
                //add their username to your g list
                ref.child(myGPath+"/\(currentUsername!)").setValue(true)
                //add your username to their f list
                ref.child(fPath+"/\(loggedInUsername)").setValue(true)
                //add your username to their contacts
                ref.child(contactsPath+"/\(loggedInUsername)").setValue(true)
                //add their username to your contacts
                ref.child(myContactsPath+"/\(currentUsername!)").setValue(true)
                
                //update local lists
                if fList.count > 0 {
                    for i in 0...fList.count-1 {
                        if(fList[i] >= loggedInUsername){
                            fList.insert(loggedInUsername, at: i)
                            break
                        }
                        else if i == fList.count-1 {
                            fList.insert(loggedInUsername, at: fList.count-1)
                            break
                        }
                    }
                }
                else {
                    fList.append(loggedInUsername)
                }
                
                
                
                followingThisUser = "g"
                DispatchQueue.main.async {
                    self.followers.setTitle("\(self.fList.count + self.hList.count)\nFollowers", for: .normal)
                    self.fghIcon.image = #imageLiteral(resourceName: "profile_icon_g")
                    self.followButton.setTitle("Followed", for: .normal)
                }
                
                //send follow notification to the profile user
                ref.child(notificationPath+"/\(loggedInUsername)").setValue(Int(NSDate().timeIntervalSince1970)) //set value as timestamp as seconds from epoch
            }
        }
        
    }
    
    func binarySearch<T:Comparable>(inputArr:Array<T>, searchItem: T) -> Int? {
        var lowerIndex = 0;
        var upperIndex = inputArr.count - 1
        
        while (true) {
            let currentIndex = (lowerIndex + upperIndex)/2
            if(inputArr[currentIndex] == searchItem) {
                return currentIndex
            } else if (lowerIndex > upperIndex) {
                return nil
            } else {
                if (inputArr[currentIndex] > searchItem) {
                    upperIndex = currentIndex - 1
                } else {
                    lowerIndex = currentIndex + 1
                }
            }
        }
    }
    
    
    
    
}
