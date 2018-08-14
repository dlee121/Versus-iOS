//
//  MeViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/13/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import AWSS3
import Nuke
import FirebaseDatabase

class MeViewController: ButtonBarPagerTabStripViewController {
    
    @IBOutlet weak var followers: UIButton!
    @IBOutlet weak var followings: UIButton!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var influence: UILabel!
    @IBOutlet weak var goldMedals: UILabel!
    @IBOutlet weak var silverMedals: UILabel!
    @IBOutlet weak var bronzeMedals: UILabel!
    
    var currentUsername : String!
    var fList = [String]()
    var gList = [String]()
    var hList = [String]()
    var ref: DatabaseReference!
    
    var fgcp = 0 //0 = f, 1 = g, c = 2, p = 3
    let f = 0
    let g = 1
    let c = 2
    let p = 3
    
    var clickedComment : VSComment?
    var clickedPost : PostObject?
    
    override func viewDidLoad() {
        print("viewDidLoad called")
        self.loadDesign()
        super.viewDidLoad()
        ref = Database.database().reference()
        DispatchQueue.main.async {
            self.profileImage.layer.cornerRadius = self.profileImage.frame.size.height / 2
            self.profileImage.clipsToBounds = true
            self.followings.titleLabel?.textAlignment = NSTextAlignment.center
            self.followers.titleLabel?.textAlignment = NSTextAlignment.center
        }
        
        

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool){
        super.viewWillAppear(animated)
        currentUsername = UserDefaults.standard.string(forKey: "KEY_USERNAME")
        let pi = UserDefaults.standard.integer(forKey: "KEY_PI")
        //profileUsername.text = currentUsername
        navigationItem.title = currentUsername
        if(pi > 0){
            setProfileImage(username: currentUsername, profileImageVersion: pi)
        }
        else{
            profileImage.image = #imageLiteral(resourceName: "default_profile")
        }
        
        setupFGH()
        
        VSVersusAPIClient.default().profileinfoGet(a: "im", b: currentUsername.lowercased()).continueWith(block:) {(task: AWSTask) -> AnyObject? in
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
                }
            }
            return nil
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
        
        ref.child(hPath).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let enumerator = snapshot.children
            while let item = enumerator.nextObject() as? DataSnapshot {
                self.hList.append(item.key)
            }
            
            
            self.ref.child(fPath).observeSingleEvent(of: .value, with: { (snapshot) in
                
                let enumerator = snapshot.children
                while let item = enumerator.nextObject() as? DataSnapshot {
                    self.fList.append(item.key)
                }
                DispatchQueue.main.async {
                    self.followers.setTitle("\(self.fList.count + self.hList.count)\nFollowers", for: .normal)
                }
                
            }) { (error) in
                print(error.localizedDescription)
            }
            
            self.ref.child(gPath).observeSingleEvent(of: .value, with: { (snapshot) in
                
                let enumerator = snapshot.children
                while let item = enumerator.nextObject() as? DataSnapshot {
                    self.gList.append(item.key)
                }
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
        (child_1 as! CommentsHistoryViewController).setUpCommentsHistory(username: UserDefaults.standard.string(forKey: "KEY_USERNAME")!, thisIsMe: true)
        (child_2 as! PostsHistoryViewController).setUpPostsHistory(username: UserDefaults.standard.string(forKey: "KEY_USERNAME")!, thisIsMe: true)
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
        performSegue(withIdentifier: "meToFGH", sender: self)
    }
    
    @IBAction func followingsTapped(_ sender: UIButton) {
        fgcp = g
        performSegue(withIdentifier: "meToFGH", sender: self)
    }
    
    func handleCommentsHistoryClick(comment : VSComment){
        fgcp = c
        clickedComment = comment
        
        if clickedComment?.parent_id == clickedComment?.post_id {
            performSegue(withIdentifier: "meToChild", sender: self) //root comment was clicked, go to child page with this root comment as top card
        }
        else {
            //child page with clicked comment (child click) or clicked comment's parent (grandchild click) as top card
            performSegue(withIdentifier: "meToGrandchild", sender: self)
        }
        
    }
    
    func handlePostsHistoryClick(post : PostObject){
        fgcp = p
        clickedPost = post
        performSegue(withIdentifier: "meToRoot", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
        switch fgcp {
        case f:
            guard let fghVC = segue.destination as? FGHViewController else {return}
            let view = fghVC.view //necessary for loading the view
            fghVC.fORg = fgcp
            fghVC.setUpFPage(followers: combineLists(list1: hList, list2: fList))
        case g:
            guard let fghVC = segue.destination as? FGHViewController else {return}
            let view = fghVC.view //necessary for loading the view
            fghVC.fORg = fgcp
            fghVC.setUpFPage(followers: combineLists(list1: hList, list2: gList))
        case c:
            //set up comments history item click segue
            if clickedComment != nil {
                if clickedComment!.root == "0" {
                    if clickedComment!.post_id == clickedComment!.parent_id { //root comment
                        
                        //go to a child page with this root comment as the top card
                        guard let childVC = segue.destination as? ChildPageViewController else {return}
                        let view = childVC.view //necessary for loading the view
                        let userActionID = currentUsername+clickedComment!.post_id
                        
                        VSVersusAPIClient.default().postGet(a: "p", b: clickedComment!.post_id).continueWith(block:) {(task: AWSTask) -> AnyObject? in
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
                                            childVC.setUpChildPage(post: postObject, comment: self.clickedComment!, userAction: UserAction(idIn: userActionID), parentPage: nil)
                                        }
                                        else {
                                            if let result = task.result {
                                                childVC.setUpChildPage(post: postObject, comment: self.clickedComment!, userAction: UserAction(itemSource: result, idIn: userActionID), parentPage: nil)
                                            }
                                            else {
                                                childVC.setUpChildPage(post: postObject, comment: self.clickedComment!, userAction: UserAction(idIn: userActionID), parentPage: nil)
                                            }
                                        }
                                        return nil
                                    }
                                }
                            }
                            return nil
                        }
                        
                    }
                    else { //child comment
                        //go to a grandchild page with this child comment as the top card
                        guard let grandchildVC = segue.destination as? GrandchildPageViewController else {return}
                        let view = grandchildVC.view //necessary for loading the view
                        let userActionID = currentUsername+clickedComment!.post_id
                        
                        VSVersusAPIClient.default().postGet(a: "p", b: clickedComment!.post_id).continueWith(block:) {(task: AWSTask) -> AnyObject? in
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
                                            grandchildVC.setUpGrandchildPage(post: postObject, comment: self.clickedComment!, userAction: UserAction(idIn: userActionID), parentPage: nil, grandparentPage: nil)
                                        }
                                        else {
                                            if let result = task.result {
                                                grandchildVC.setUpGrandchildPage(post: postObject, comment: self.clickedComment!, userAction: UserAction(itemSource: result, idIn: userActionID), parentPage: nil, grandparentPage: nil)
                                                
                                            }
                                            else {
                                                grandchildVC.setUpGrandchildPage(post: postObject, comment: self.clickedComment!, userAction: UserAction(idIn: userActionID), parentPage: nil, grandparentPage: nil)
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
                else { //grandchild comment
                    //go to a grandchild page with this grandchild comment's parent comment as the top card
                    guard let grandchildVC = segue.destination as? GrandchildPageViewController else {return}
                    let view = grandchildVC.view //necessary for loading the view
                    let userActionID = currentUsername+clickedComment!.post_id
                    
                    VSVersusAPIClient.default().postGet(a: "p", b: clickedComment!.post_id).continueWith(block:) {(task: AWSTask) -> AnyObject? in
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
                                
                                VSVersusAPIClient.default().commentGet(a: "c", b: self.clickedComment?.parent_id).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                                    if task.error != nil {
                                        DispatchQueue.main.async {
                                            print(task.error!)
                                        }
                                    }
                                    else {
                                        if let commentResult = task.result { //this parent (child) of the clicked comment (grandchild), for the top card
                                            
                                            let topcardComment = VSComment(itemSource: commentResult.source!, id: commentResult.id!)
                                            
                                            VSVersusAPIClient.default().recordGet(a: "rcg", b: userActionID).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                                                
                                                if task.error != nil {
                                                    grandchildVC.setUpGrandchildPage(post: postObject, comment: topcardComment, userAction: UserAction(idIn: userActionID), parentPage: nil, grandparentPage: nil)
                                                }
                                                else {
                                                    if let result = task.result {
                                                        grandchildVC.setUpGrandchildPage(post: postObject, comment: topcardComment, userAction: UserAction(itemSource: result, idIn: userActionID), parentPage: nil, grandparentPage: nil)
                                                        
                                                    }
                                                    else {
                                                        grandchildVC.setUpGrandchildPage(post: postObject, comment: topcardComment, userAction: UserAction(idIn: userActionID), parentPage: nil, grandparentPage: nil)
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
            }
            
        case p:
            //set up posts history item click segue
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
    

}
