//
//  MCViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 6/29/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import FirebaseDatabase
import Nuke
import AWSS3
import XLPagerTabStrip
import PopupDialog

class Tab1TrendingViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ProfileDelegator {
    
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var categorySelectionLabel: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var fromIndex = 0
    let DEFAULT = 0
    let S3 = 1
    var posts = [PostObject]()
    var vIsRed = true
    let preheater = Nuke.ImagePreheater()
    var profileImageVersions = [String : Int]()
    
    
    var prepareCategoryFilter = false
    var categorySelection : String? = nil
    var nowLoading = false
    var loadThreshold = 8
    var retrievalSize = 16
    
    var clickLock = false
    let cellSpacingHeight: CGFloat = 16
    
    var nextAdIndex = 2
    
    var queryTime : Int!
    
    var hiddenSections = NSMutableSet()
    var blockedUsernames = NSMutableSet()
    
    private let refreshControl = UIRefreshControl()
    
    var currPostIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(Tab1TrendingViewController.resetCategorySelection))
        categorySelectionLabel.addGestureRecognizer(tap)
        
        if posts.count == 0 {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH\\:mm\\:ssZ"
            queryTime = Int(Date().timeIntervalSince1970.rounded())
            
            trendingQuery()
        }
        
        // Add Refresh Control to Table View
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        
        // Configure Refresh Control
        refreshControl.addTarget(self, action: #selector(refreshList(_:)), for: .valueChanged)
    }
    
    @objc private func refreshList(_ sender: Any) {
        refresh()
    }
    
    func refresh(){
        if !indicator.isAnimating {
            fromIndex = 0
            posts.removeAll()
            tableView.reloadData()
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH\\:mm\\:ssZ"
            queryTime = Int(Date().timeIntervalSince1970.rounded())
            
            trendingQuery()
        }
        else {
            refreshControl.endRefreshing()
        }
    }
    
    func scrollOrRefresh() {
        if tableView != nil  && posts != nil && posts.count > 0 && !indicator.isAnimating {
            if tableView.contentOffset.y == 0.0 {
                refreshList(0)
                
            }
            else {
                tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clickLock = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        clickLock = false
    }
    
    func trendingQuery(){
        if fromIndex == 0 {
            currPostIndex = 0
            nextAdIndex = 2
            if let blockList = UserDefaults.standard.object(forKey: "KEY_BLOCKS") as? [String] {
                if blockedUsernames.count > 0 {
                    blockedUsernames.removeAllObjects()
                }
                blockedUsernames.addObjects(from: blockList)
            }
        }
        
        //print("trending query started")
        DispatchQueue.main.async {
            if !self.indicator.isAnimating && !self.refreshControl.isRefreshing {
                self.indicator.startAnimating()
            }
        }
        //print("queryTime = \(queryTime!)")
        VSVersusAPIClient.default().postslistGet(c: categorySelection, d: "\(queryTime!)", a: "tr2", b: "\(fromIndex)").continueWith(block:) {(task: AWSTask) -> AnyObject? in
            if task.error != nil {
                DispatchQueue.main.async {
                    print(task.error!)
                }
            }
            else {
                let queryResults = task.result?.hits?.hits
                var loadedItemsCount = queryResults!.count
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
                    
                    self.currPostIndex += 1
                    
                    if self.currPostIndex == self.nextAdIndex {
                        self.posts.append(PostObject())
                        loadedItemsCount += 1
                        self.nextAdIndex += 5
                    }
                    
                }
                pivString += "]}"
                
                print(pivString)
                if index > 0 {
                    VSVersusAPIClient.default().pivGet(a: "pis", b: pivString.lowercased()).continueWith(block:) {(task: AWSTask) -> AnyObject? in
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
                                    self.tableView.reloadData()
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
                                    let indexSet = IndexSet(self.fromIndex...self.fromIndex+loadedItemsCount-1)
                                    self.tableView.insertSections(indexSet, with: .fade)
                                    
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
                            self.tableView.reloadData()
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
                            let indexSet = IndexSet(self.fromIndex...self.fromIndex+loadedItemsCount-1)
                            self.tableView.insertSections(indexSet, with: .fade)
                            
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
    
    func overflowTapped(postID: String, sender: UIButton, rowNumber: Int) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.popoverPresentationController?.sourceView = sender
        alert.popoverPresentationController?.sourceRect = sender.bounds
        
        alert.addAction(UIAlertAction(title: "Hide", style: .default, handler: { _ in
            self.hiddenSections.add(postID)
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: rowNumber)], with: .automatic)
            self.showToast(message: "Post hidden.", length: 14)
        }))
        
        alert.addAction(UIAlertAction(title: "Report", style: .default, handler: { _ in
            // Prepare the popup assets
            let title = "Report this post?"
            let message = ""
            
            // Create the dialog
            let popup = PopupDialog(title: title, message: message)
            
            // Create buttons
            let buttonOne = DefaultButton(title: "No", action: nil)
            
            // This button will not the dismiss the dialog
            let buttonTwo = DefaultButton(title: "Yes") {
                let postReportPath = "reports/p/\(postID)/"
                Database.database().reference().child(postReportPath).setValue(true)
                self.showToast(message: "Post reported.", length: 17)
            }
            
            popup.addButtons([buttonOne, buttonTwo])
            popup.buttonAlignment = .horizontal
            
            // Present dialog
            self.present(popup, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
        
        
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let post = posts[indexPath.section]
        if hiddenSections.contains(post.post_id) || blockedUsernames.contains(post.author) {
            return 0
        }
        else {
            return UITableViewAutomaticDimension
        }
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let post = posts[section]
        if hiddenSections.contains(post.post_id) || blockedUsernames.contains(post.author) {
            return 0
        }
        else {
            return cellSpacingHeight
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let post = posts[indexPath.section]
        
        if post.post_id != "0" {
            if post.redimg.intValue % 10 == S3 || post.blackimg.intValue % 10 == S3 {
                return 339
            }
            else {
                return 124
            }
        }
        else {
            return 339
        }
        
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentPost = posts[indexPath.section]
        
        
        if currentPost.post_id != "0" {
            //set profile image version for the post if one exists
            if let piv = profileImageVersions[currentPost.author.lowercased()] {
                currentPost.setProfileImageVersion(piv: piv)
            }
            
            if currentPost.redimg.intValue % 10 == S3 || currentPost.blackimg.intValue % 10 == S3 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "vscard_images", for: indexPath) as! PostImageTableViewCell
                cell.setCell(post: currentPost, vIsRed: vIsRed, row: indexPath.section)
                vIsRed = !vIsRed
                cell.delegate = self
                
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "vscard_texts", for: indexPath) as! PostTextTableViewCell
                cell.setCell(post: currentPost, vIsRed: vIsRed, row: indexPath.section)
                vIsRed = !vIsRed
                cell.delegate = self
                
                return cell
            }
        }
        else { //nativeAd
            let mainVC = parent as! MCViewController
            var cell = UITableViewCell(style: .default, reuseIdentifier: "NativeImage")
            mainVC.presentNative(onView: cell.contentView, fromIndex: indexPath as NSIndexPath, showMedia: true)
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastElement = posts.count - 1 - loadThreshold
        if !nowLoading && indexPath.section == lastElement {
            nowLoading = true
            fromIndex = posts.count
            trendingQuery()
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentPost = posts[indexPath.section]
        
        if currentPost.post_id != "0" {
            if !clickLock {
                clickLock = true
                let mainVC = parent as! MCViewController
                mainVC.goToPostPageRoot(post: currentPost)
            }
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
        performSegue(withIdentifier: "presentTrendingFilter", sender: self)
        
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if prepareCategoryFilter {
            guard let categoriesVC = segue.destination as? CategoryFilterViewController else {return}
            categoriesVC.sourceType = 2
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

extension Tab1TrendingViewController : IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Trending")
    }
}
