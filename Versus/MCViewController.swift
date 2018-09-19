//
//  TabViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/8/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import Firebase
import FirebaseMessaging
import Appodeal

class MCViewController: ButtonBarPagerTabStripViewController, UISearchControllerDelegate {
    
    var searchController : UISearchController!
    var searchViewController : SearchViewController!
    var selectedPost : PostObject!
    
    var mainSegueType : Int!
    let myCircleSegue = 0
    let mainSeguePostSegue = 1
    
    var clickedComment : VSComment?
    var clickedCommentPostPIV : Int?
    
    var segueType = 0
    
    let postSegue = 0
    let rootSegue = 1
    let childSegue = 2
    let grandchildSegue = 3
    let followerSegue = 4
    let profileSegue = 5
    
    var tappedUsername : String!
    
    var segueComment, segueTopCardComment : VSComment?
    var clickedPost, seguePost : PostObject?
    var segueUserAction : UserAction?
    
    var currentUsername : String!
    var availableAdCount = 0
    
    private var adQueue : APDNativeAdQueue = APDNativeAdQueue()
    fileprivate var nativeArray : [APDNativeAd]! = Array()
    
    override func viewDidLoad() {
        self.loadDesign()
        super.viewDidLoad()
        currentUsername = UserDefaults.standard.string(forKey: "KEY_USERNAME")
        searchViewController = storyboard!.instantiateViewController(withIdentifier: "searchViewController") as? SearchViewController
        searchViewController.mainContainer = self
        // Do any additional setup after loading the view.
        self.searchController = UISearchController(searchResultsController:  searchViewController)
        
        self.searchController.searchResultsUpdater = searchViewController
        self.searchController.delegate = self
        self.searchController.searchBar.delegate = searchViewController
        
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.dimsBackgroundDuringPresentation = true
        
        searchController = UISearchController(searchResultsController: searchViewController)
        searchController.delegate = self
        searchController.searchResultsUpdater = searchViewController
        searchController.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        searchController.loadViewIfNeeded()
        
        //Configura a barra do Controlador de busca
        searchController.searchBar.delegate = searchViewController!
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = "Search by keyword(s) or question"
        searchController.searchBar.sizeToFit()
        searchController.searchBar.barTintColor = navigationController?.navigationBar.barTintColor
        searchController.searchBar.tintColor = self.view.tintColor
        
        self.navigationItem.titleView = searchController.searchBar
        
        self.definesPresentationContext = true
        
        adQueue.settings.adViewClass = NativeAdTableViewCell.self
        adQueue.settings.autocacheMask = [.icon, .media]
        adQueue.settings.type = .noVideo
        
        adQueue.delegate = self
        self.currentAd.delegate = self
        adQueue.setMaxAdSize(2) //deprecated
        adQueue.loadAd()
        
        
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        print("called here 1")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let child_1 = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Tab1")
        let child_2 = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Tab2")
        let child_3 = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Tab3")
        return [child_1, child_2, child_3]
    }
    
    func loadDesign() {
        print("point3")
        //self.settings.style.buttonBarHeight = 325.0
        self.settings.style.buttonBarBackgroundColor = .white
        self.settings.style.buttonBarItemBackgroundColor = .white
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
    
    func goToPostPageRoot(post : PostObject){
        selectedPost = post
        mainSegueType = mainSeguePostSegue
        performSegue(withIdentifier: "mainToRoot", sender: self)
        
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
                                self.seguePost!.profileImageVersion = self.clickedCommentPostPIV!
                                
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
                                                self.performSegue(withIdentifier: "mainToRoot", sender: self)
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
                                                            self.performSegue(withIdentifier: "mainToChild", sender: self)
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
                                                        self.performSegue(withIdentifier: "mainToGrandchild", sender: self)
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
    
    func myCircleItemClick(comment : VSComment, postProfileImage : Int){
        mainSegueType = myCircleSegue
        clickedComment = comment
        clickedCommentPostPIV = postProfileImage
        
        goToComment(commentID: comment.comment_id)
        
    }
    
    func goToProfile(username : String) {
        mainSegueType = profileSegue
        tappedUsername = username
        
        performSegue(withIdentifier: "mainToProfile", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch mainSegueType {
        case mainSeguePostSegue:
            guard let rootVC = segue.destination as? RootPageViewController else {return}
            let rootView = rootVC.view //load the view before segue
            
            let userActionId = currentUsername + selectedPost.post_id
            VSVersusAPIClient.default().recordGet(a: "rcg", b: userActionId).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                if task.error != nil {
                    rootVC.setUpRootPage(post: self.selectedPost, userAction: UserAction(idIn: userActionId), fromCreatePost: false)
                }
                else {
                    if let result = task.result {
                        rootVC.setUpRootPage(post: self.selectedPost, userAction: UserAction(itemSource: result, idIn: userActionId), fromCreatePost: false)
                    }
                    else {
                        rootVC.setUpRootPage(post: self.selectedPost, userAction: UserAction(idIn: userActionId), fromCreatePost: false)
                    }
                }
                return nil
            }
            
        case profileSegue:
            guard let profileVC = segue.destination as? ProfileViewController else {return}
            profileVC.fromPostPage = false
            profileVC.currentUsername = tappedUsername!
            
        case myCircleSegue:
            switch segueType {
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
            default:
                break
            }
            
        default:
            break
            
        }
        
        
        
        
    }
    
}

extension MCViewController : APDNativeAdPresentationDelegate {
    
    func nativeAdWillLogImpression(_ nativeAd: APDNativeAd!) {
    }
    
    func nativeAdWillLogUserInteraction(_ nativeAd: APDNativeAd!) {
    }
}

extension MCViewController : APDNativeAdQueueDelegate {
    
    func adQueue(_ adQueue: APDNativeAdQueue!, failedWithError error: Error!) {
    }
    
    func adQueueAdIsAvailable(_ adQueue: APDNativeAdQueue!, ofCount count: UInt) {
        if nativeArray.count > 0 {
            availableAdCount = nativeArray.count + Int(count)
        } else {
            nativeArray.append(contentsOf:adQueue.getNativeAds(ofCount: 1))
            let _ = nativeArray.map {( $0.delegate = self )}
            availableAdCount = Int(count)
        }
        //apdNativeArray will contain all available
    }
    
}
