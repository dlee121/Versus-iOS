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

class MCViewController: ButtonBarPagerTabStripViewController, UISearchControllerDelegate {
    
    var searchController : UISearchController!
    var searchViewController : SearchViewController!
    var selectedPost : PostObject!
    let apiClient = VSVersusAPIClient.default()
    var segueType : Int!
    let myCircleSegue = 0
    let postSegue = 1
    let logoutSegue = 2
    var clickedComment : VSComment?
    var clickedCommentPostPIV : Int?
    
    override func viewDidLoad() {
        self.loadDesign()
        super.viewDidLoad()
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
    
    @IBAction func logOutTapped(_ sender: UIButton) {
        //remove session data, log out firebase user, then segue back to start screen
        UserDefaults.standard.removeObject(forKey: "KEY_BDAY")
        UserDefaults.standard.removeObject(forKey: "KEY_EMAIL")
        UserDefaults.standard.removeObject(forKey: "KEY_USERNAME")
        UserDefaults.standard.removeObject(forKey: "KEY_PI")
        UserDefaults.standard.removeObject(forKey: "KEY_IS_NATIVE")
        try! Auth.auth().signOut()
        segueType = logoutSegue
        performSegue(withIdentifier: "logOutToStart", sender: self)
        self.view.window!.rootViewController?.dismiss(animated: false, completion: nil)
    }
    
    
    func goToPostPageRoot(post : PostObject){
        selectedPost = post
        segueType = postSegue
        performSegue(withIdentifier: "mainToRoot", sender: self)
        
    }
    
    func myCircleItemClick(comment : VSComment, postProfileImage : Int){
        segueType = myCircleSegue
        clickedComment = comment
        clickedCommentPostPIV = postProfileImage
        if comment.root == "0" {
            if comment.post_id == comment.parent_id { //root comment
                performSegue(withIdentifier: "mainToChild", sender: self)
            }
            else { //child comment
                performSegue(withIdentifier: "mainToGrandchild", sender: self)
            }
        }
        else { //grandchild comment
            performSegue(withIdentifier: "mainToGrandchild", sender: self)
        }
        
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueType {
        case postSegue:
            guard let rootVC = segue.destination as? RootPageViewController else {return}
            let rootView = rootVC.view //load the view before segue
            
            let userActionId = UserDefaults.standard.string(forKey: "KEY_USERNAME")! + selectedPost.post_id
            apiClient.recordGet(a: "rcg", b: userActionId).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                if task.error != nil {
                    rootVC.setUpRootPage(post: self.selectedPost, userAction: UserAction(idIn: userActionId))
                }
                else {
                    if let result = task.result {
                        rootVC.setUpRootPage(post: self.selectedPost, userAction: UserAction(itemSource: result, idIn: userActionId))
                    }
                    else {
                        rootVC.setUpRootPage(post: self.selectedPost, userAction: UserAction(idIn: userActionId))
                    }
                }
                return nil
            }
            
        case myCircleSegue:
            //set up comments history item click segue
            if clickedComment != nil {
                if clickedComment!.root == "0" {
                    if clickedComment!.post_id == clickedComment!.parent_id { //root comment
                        
                        //go to a child page with this root comment as the top card
                        guard let childVC = segue.destination as? ChildPageViewController else {return}
                        let view = childVC.view //necessary for loading the view
                        let userActionID = UserDefaults.standard.string(forKey: "KEY_USERNAME")!+clickedComment!.post_id
                        
                        apiClient.postGet(a: "p", b: clickedComment!.post_id).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                            if task.error != nil {
                                DispatchQueue.main.async {
                                    print(task.error!)
                                }
                            }
                            else {
                                if let postResult = task.result {
                                    
                                    let postObject = PostObject(itemSource: postResult.source!, id: postResult.id!)
                                    postObject.profileImageVersion = self.clickedCommentPostPIV!
                                    
                                    self.apiClient.recordGet(a: "rcg", b: userActionID).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                                        
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
                        let userActionID = UserDefaults.standard.string(forKey: "KEY_USERNAME")!+clickedComment!.post_id
                        
                        apiClient.postGet(a: "p", b: clickedComment!.post_id).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                            if task.error != nil {
                                DispatchQueue.main.async {
                                    print(task.error!)
                                }
                            }
                            else {
                                if let postResult = task.result {
                                    
                                    let postObject = PostObject(itemSource: postResult.source!, id: postResult.id!)
                                    postObject.profileImageVersion = self.clickedCommentPostPIV!
                                    
                                    self.apiClient.recordGet(a: "rcg", b: userActionID).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                                        
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
                    let userActionID = UserDefaults.standard.string(forKey: "KEY_USERNAME")!+clickedComment!.post_id
                    
                    
                    apiClient.postGet(a: "p", b: clickedComment!.post_id).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                        if task.error != nil {
                            DispatchQueue.main.async {
                                print(task.error!)
                            }
                        }
                        else {
                            if let postResult = task.result {
                                
                                let postObject = PostObject(itemSource: postResult.source!, id: postResult.id!)
                                postObject.profileImageVersion = self.clickedCommentPostPIV!
                                
                                self.apiClient.commentGet(a: "c", b: self.clickedComment?.parent_id).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                                    if task.error != nil {
                                        DispatchQueue.main.async {
                                            print(task.error!)
                                        }
                                    }
                                    else {
                                        if let commentResult = task.result { //this parent (child) of the clicked comment (grandchild), for the top card
                                            
                                            let topcardComment = VSComment(itemSource: commentResult.source!, id: commentResult.id!)
                                            
                                            self.apiClient.recordGet(a: "rcg", b: userActionID).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                                                
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
            
            
        default:
            break
            
        }
        
        
        
        
    }
    
}
