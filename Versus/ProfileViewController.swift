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
    
    var currentUsername : String!
    var fList = [String]()
    var gList = [String]()
    var hList = [String]()
    var ref: DatabaseReference!
    
    var followingThisUser = "0" //0 by default, f if this is my follower, g if I'm following them, and h if both
    
    var fORg = 0 //0 = f, 1 = g, for segue to FGH page from followers/followings tap
    let f = 0
    let g = 1
    
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
        
        //navigationItem.leftBarButtonItem?.setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name: "Chalkduster", size: 5)!], for: .normal)
        
        
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool){
        super.viewWillAppear(animated)
        self.fghIcon.image = nil
        setupFGH()
        
        VSVersusAPIClient.default().profileinfoGet(a: "pim", b: currentUsername.lowercased()).continueWith(block:) {(task: AWSTask) -> AnyObject? in
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
                self.followButton.setTitle("Unfollow", for: .normal)
                self.fghIcon.image = #imageLiteral(resourceName: "profile_icon_g")
            case "h":
                self.followButton.setTitle("Unfollow", for: .normal)
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
        (child_1 as! CommentsHistoryViewController).setUpCommentsHistory(username: currentUsername)
        (child_2 as! PostsHistoryViewController).setUpPostsHistory(username: currentUsername)
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
        fORg = f
        performSegue(withIdentifier: "profileToFGH", sender: self)
    }
    
    @IBAction func followingsTapped(_ sender: UIButton) {
        fORg = g
        performSegue(withIdentifier: "profileToFGH", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let fghVC = segue.destination as? FGHViewController else {return}
        let view = fghVC.view
        if fORg == f {
            //combine f and h list then sort them alphabetically
            fghVC.setUpFPage(followers: combineLists(list1: hList, list2: fList))
        }
        else {
            //combine g and h list then sort them alphabetically
            fghVC.setUpFPage(followers: combineLists(list1: hList, list2: gList))
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
        
        
        
    }
    
    
    
    
}
