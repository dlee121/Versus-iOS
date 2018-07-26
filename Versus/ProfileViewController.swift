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
    
    @IBOutlet weak var followings: UILabel!
    @IBOutlet weak var followers: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var influence: UILabel!
    @IBOutlet weak var goldMedals: UILabel!
    @IBOutlet weak var silverMedals: UILabel!
    @IBOutlet weak var bronzeMedals: UILabel!
    
    var currentUsername : String!
    
    override func viewDidLoad() {
        self.loadDesign()
        super.viewDidLoad()
        navigationItem.title = currentUsername
        DispatchQueue.main.async {
            self.profileImage.layer.cornerRadius = self.profileImage.frame.size.height / 2
            self.profileImage.clipsToBounds = true
        }
        
        //navigationItem.leftBarButtonItem?.setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name: "Chalkduster", size: 5)!], for: .normal)
        
        
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool){
        super.viewWillAppear(animated)
        
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
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let child_1 = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CommentsHistory")
        let child_2 = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PostsHistory")
        (child_1 as! CommentsHistoryViewController).setUpCommentsHistory(username: currentUsername)
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
            Nuke.loadImage(with: presignedURL!.absoluteURL!, into: self.profileImage)
            print("\(self.profileImage.frame.width) is width")
            
            return nil
        }
        
    }
    
}
