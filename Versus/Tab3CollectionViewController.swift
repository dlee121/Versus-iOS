//
//  MCViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 6/29/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import Firebase
import Nuke
import AWSS3
import XLPagerTabStrip

class Tab3CollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, ProfileDelegator {
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var categoryFilterButton: UIButton!
    @IBOutlet weak var categorySelectionLabel: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    
    var fromIndex = 0
    let DEFAULT = 0
    let S3 = 1
    let apiClient = VSVersusAPIClient.default()
    var posts = [PostObject]()
    var vIsRed = true
    let preheater = Nuke.ImagePreheater()
    var profileImageVersions = [String : Int]()
    
    var screenWidth : CGFloat!
    var textsVSCHeight : CGFloat!
    
    var prepareCategoryFilter = false
    var categorySelection : String? = nil
    var nowLoading = false
    var loadThreshold = 8
    var retrievalSize = 16
    
    var clickLock = false
    
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        screenWidth = self.view.frame.size.width
        textsVSCHeight = screenWidth / 1.6
        
        DispatchQueue.main.async {
            let labelWidth = self.categoryFilterButton.titleLabel!.frame.size.width
            let imageWidth = self.categoryFilterButton.imageView!.frame.size.width
            self.categoryFilterButton.titleEdgeInsets = UIEdgeInsetsMake(0.0,-imageWidth,0.0,imageWidth)
            self.categoryFilterButton.imageEdgeInsets = UIEdgeInsetsMake(0.0,labelWidth,0.0,-labelWidth)
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(Tab3CollectionViewController.resetCategorySelection))
        categorySelectionLabel.addGestureRecognizer(tap)
        
        if posts.count == 0 {
            newQuery()
        }
        
        // Add Refresh Control to Table View
        if #available(iOS 10.0, *) {
            collectionView.refreshControl = refreshControl
        } else {
            collectionView.addSubview(refreshControl)
        }
        
        // Configure Refresh Control
        refreshControl.addTarget(self, action: #selector(refreshList(_:)), for: .valueChanged)
    }
    
    @objc private func refreshList(_ sender: Any) {
        refresh()
    }
    
    func refresh(){
        fromIndex = 0
        posts.removeAll()
        collectionView.reloadData()
        newQuery()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clickLock = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        clickLock = false
    }
    
    
    func newQuery(){
        //print("new query started")
        DispatchQueue.main.async {
            if !self.indicator.isAnimating && !self.refreshControl.isRefreshing {
                self.indicator.startAnimating()
            }
        }
        
        self.apiClient.postslistGet(c: categorySelection, d: nil, a: "nw", b: "\(fromIndex)").continueWith(block:) {(task: AWSTask) -> AnyObject? in
            if task.error != nil {
                DispatchQueue.main.async {
                    print(task.error!)
                }
            }
            else {
                let queryResults = task.result?.hits?.hits
                var pivString = "{\"ids\":["
                var index = 0
                for item in queryResults! {
                    self.posts.append(PostObject(itemSource: item.source!, id: item.id!))
                    
                    if item.source?.a != "deleted" {
                        if index == 0 {
                            pivString += "\"" + item.source!.a! + "\""
                        }
                        else {
                            pivString += ",\"" + item.source!.a! + "\""
                        }
                        index += 1
                    }
                }
                pivString += "]}"
                
                print(pivString)
                if index > 0 {
                    self.apiClient.pivGet(a: "pis", b: pivString.lowercased()).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                        if task.error != nil {
                            DispatchQueue.main.async {
                                print(task.error!)
                            }
                        }
                        
                        if let results = task.result?.docs {
                            for item in results {
                                self.profileImageVersions[item.id!] = item.source?.pi?.intValue
                            }
                            
                            if self.fromIndex == 0 {
                                DispatchQueue.main.async {
                                    self.collectionView.reloadData()
                                    if self.refreshControl.isRefreshing {
                                        self.refreshControl.endRefreshing()
                                    }
                                    else {
                                        self.indicator.stopAnimating()
                                    }
                                }
                            }
                            else {
                                DispatchQueue.main.async {
                                    var indexPaths = [IndexPath]()
                                    for i in 0...queryResults!.count-1 {
                                        indexPaths.append(IndexPath(row: self.fromIndex+i, section: 0))
                                    }
                                    
                                    self.collectionView.insertItems(at: indexPaths)
                                    
                                    if self.refreshControl.isRefreshing {
                                        self.refreshControl.endRefreshing()
                                    }
                                    else {
                                        self.indicator.stopAnimating()
                                    }
                                }
                            }
                            if queryResults!.count < self.retrievalSize {
                                self.nowLoading = true
                            }
                            else {
                                self.nowLoading = false
                            }
                            
                        }
                        
                        return nil
                    }
                }
                else {
                    if self.fromIndex == 0 {
                        DispatchQueue.main.async {
                            self.collectionView.reloadData()
                            if self.refreshControl.isRefreshing {
                                self.refreshControl.endRefreshing()
                            }
                            else {
                                self.indicator.stopAnimating()
                            }
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            var indexPaths = [IndexPath]()
                            for i in 0...queryResults!.count-1 {
                                indexPaths.append(IndexPath(row: self.fromIndex+i, section: 0))
                            }
                            
                            self.collectionView.insertItems(at: indexPaths)
                            
                            if self.refreshControl.isRefreshing {
                                self.refreshControl.endRefreshing()
                            }
                            else {
                                self.indicator.stopAnimating()
                            }
                        }
                    }
                    if queryResults!.count < self.retrievalSize {
                        self.nowLoading = true
                    }
                    else {
                        self.nowLoading = false
                    }
                    
                }
                
                
            }
            return nil
        }
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let post = posts[indexPath.row]
        if post.redimg.intValue % 10 == S3 || post.blackimg.intValue % 10 == S3 {
            return CGSize(width: screenWidth, height: screenWidth)
        }
        else {
            return CGSize(width: screenWidth, height: textsVSCHeight)
        }
        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let currentPost = posts[indexPath.row]
        
        //set profile image version for the post if one exists
        if let piv = profileImageVersions[currentPost.author.lowercased()] {
            currentPost.setProfileImageVersion(piv: piv)
        }
        
        if currentPost.redimg.intValue % 10 == S3 || currentPost.blackimg.intValue % 10 == S3 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "vscard_images", for: indexPath) as! PostImageCollectionViewCell
            cell.setCell(post: currentPost, vIsRed: vIsRed)
            vIsRed = !vIsRed
            cell.delegate = self
            
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "vscard_texts", for: indexPath) as! PostTextCollectionViewCell
            cell.setCell(post: currentPost, vIsRed: vIsRed)
            vIsRed = !vIsRed
            cell.delegate = self
            
            return cell
        }
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let lastElement = posts.count - 1 - loadThreshold
        if !nowLoading && indexPath.row == lastElement {
            nowLoading = true
            fromIndex = posts.count
            newQuery()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !clickLock {
            clickLock = true
            let mainVC = parent as! MCViewController
            mainVC.goToPostPageRoot(post: posts[indexPath.row])
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    func prefetchPostImage(indexPaths: [IndexPath]){
        var imageRequests = [ImageRequest]()
        print("heyhey let's see if it's async")
        var index = 0
        for indexPath in indexPaths {
            let post = posts[indexPath.row]
            let redimg = post.redimg.intValue
            let blackimg = post.blackimg.intValue
            if redimg % 10 == S3 {
                let request = AWSS3GetPreSignedURLRequest()
                request.expires = Date().addingTimeInterval(86400)
                request.bucket = "versus.pictures"
                request.httpMethod = .GET
                
                if redimg / 10 == 0 {
                    request.key = post.post_id + "-left.jpeg"
                }
                else{
                    request.key = post.post_id + "-left\(redimg/10).jpeg"
                }
                
                AWSS3PreSignedURLBuilder.default().getPreSignedURL(request).continueWith { (task:AWSTask<NSURL>) -> Any? in
                    if let error = task.error {
                        print("Error: \(error)")
                        return nil
                    }
                    
                    var prefetchRequest = ImageRequest(url: task.result!.absoluteURL!)
                    prefetchRequest.priority = .low
                    
                    imageRequests.append(prefetchRequest)
                    print("heyhey appended \(index)")
                    
                    return nil
                }
            }
            
            if blackimg % 10 == S3 {
                let request = AWSS3GetPreSignedURLRequest()
                request.expires = Date().addingTimeInterval(86400)
                request.bucket = "versus.pictures"
                request.httpMethod = .GET
                
                if blackimg / 10 == 0 {
                    request.key = post.post_id + "-left.jpeg"
                }
                else{
                    request.key = post.post_id + "-left\(blackimg/10).jpeg"
                }
                
                AWSS3PreSignedURLBuilder.default().getPreSignedURL(request).continueWith { (task:AWSTask<NSURL>) -> Any? in
                    if let error = task.error {
                        print("Error: \(error)")
                        return nil
                    }
                    
                    var prefetchRequest = ImageRequest(url: task.result!.absoluteURL!)
                    prefetchRequest.priority = .low
                    
                    imageRequests.append(prefetchRequest)
                    print("heyhey appended \(index)")
                    
                    return nil
                }
            }
            index += 1
        }
        
        print("heyhey executed prefetch")
        preheater.startPreheating(with: imageRequests)
    }
    
    func prefetchProfileImage(indexPaths: [IndexPath]){
        print("hiho let's see if it's async")
        var imageRequests = [ImageRequest]()
        var index = 0
        for indexPath in indexPaths {
            let username = posts[indexPath.row].author
            if let piv = profileImageVersions[username] {
                let request = AWSS3GetPreSignedURLRequest()
                request.expires = Date().addingTimeInterval(86400)
                request.bucket = "versus.profile-pictures"
                request.httpMethod = .GET
                request.key = username + "-\(piv).jpeg"
                
                AWSS3PreSignedURLBuilder.default().getPreSignedURL(request).continueWith { (task:AWSTask<NSURL>) -> Any? in
                    if let error = task.error {
                        print("Error: \(error)")
                        return nil
                    }
                    
                    
                    var prefetchRequest = ImageRequest(url: task.result!.absoluteURL!)
                    prefetchRequest.priority = .low
                    
                    imageRequests.append(prefetchRequest)
                    print("hiho appended \(index)")
                    index += 1
                    
                    return nil
                }
                
            }
        }
        
        preheater.startPreheating(with: imageRequests)
        print("hiho executed prefetch")
        
    }
    
    @IBAction func categoryFilterButtonTapped(_ sender: UIButton) {
        prepareCategoryFilter = true
        performSegue(withIdentifier: "presentNewFilter", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if prepareCategoryFilter {
            guard let categoriesVC = segue.destination as? CategoryFilterViewController else {return}
            categoriesVC.tab2Or3OrCP = 3
            categoriesVC.originVC = self
        }
        else { //this is for segue to PostPage. Be sure to set prepareCategoryFilter = false to access this block
            
            //TODO: handle preparation for post item click here
        }
        
    }
    
    @objc
    func resetCategorySelection(sender:UITapGestureRecognizer) {
        categorySelection = nil
        categorySelectionLabel.text = ""
        refresh()
    }
    
    func goToProfile(username: String) {
        if !clickLock {
            clickLock = true
            
            let mainVC = parent as! MCViewController
            
            mainVC.goToProfile(username: username)
        }
    }
    
    
}

extension Tab3CollectionViewController : IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "New")
    }
}
