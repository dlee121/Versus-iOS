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
        performSegue(withIdentifier: "logOutToStart", sender: self)
    }
    
    func goToPostPageRoot(){
        performSegue(withIdentifier: "mainToRoot", sender: self)
        
    }
    
    func goToPostPageRoot(post : PostObject){
        selectedPost = post
        performSegue(withIdentifier: "mainToRoot", sender: self)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let rootVC = segue.destination as? RootPageViewController else {return}
        let rootView = rootVC.view //load the view before segue
        rootVC.setUpRootPage(post: selectedPost)
    }
    
}
