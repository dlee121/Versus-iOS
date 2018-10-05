//
//  MCViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 6/29/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import Nuke
import AWSS3
import XLPagerTabStrip
import FirebaseDatabase
import Appodeal
import PopupDialog

class Tab1CollectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MyCircleDelegator {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    var fromIndex : Int!
    let DEFAULT = 0
    let S3 = 1
    var comments = [VSComment]()
    var postInfos = [String : VSPostQMultiModel_docs_item__source]()
    var vIsRed = true
    let preheater = Nuke.ImagePreheater()
    var profileImageVersions = [String : Int]()
    var screenWidth : CGFloat!
    var textsVSCHeight : CGFloat!
    var gList = [String]()
    var ref : DatabaseReference!
    var currentUsername : String!
    let retrievalSize = 16
    var nowLoading = false
    var loadThreshold = 8
    var tappedUsername : String!
    
    var clickLock = false
    
    var expandedCells = NSMutableSet()
    
    let cellSpacingHeight: CGFloat = 16
    
    private let refreshControl = UIRefreshControl()
    
    var adFrequency = 11
    var queryTime : String!
    
    var adjustForSmallerScreen = false
    
    var hiddenSections = NSMutableSet()
    
    var blockedUsernames = NSMutableSet()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        adjustForSmallerScreen = UIScreen.main.bounds.height < 666
        
        tableView.tableFooterView = UIView()
        ref = Database.database().reference()
        screenWidth = self.view.frame.size.width
        textsVSCHeight = screenWidth / 1.6
        tableView.separatorStyle = .none
        
        if comments.count == 0 {
            myCircleInitialSetup()
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
        if !indicator.isAnimating {
            comments.removeAll()
            tableView.reloadData()
            myCircleInitialSetup()
        }
        else {
            refreshControl.endRefreshing()
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
    
    func myCircleInitialSetup(){
        if let blockList = UserDefaults.standard.object(forKey: "KEY_BLOCKS") as? [String] {
            if blockedUsernames.count > 0 {
                blockedUsernames.removeAllObjects()
            }
            blockedUsernames.addObjects(from: blockList)
        }
        
        expandedCells.removeAllObjects()
        
        if !refreshControl.isRefreshing {
            indicator.startAnimating()
        }
        
        fromIndex = 0
        var usernameHash : Int32
        currentUsername = UserDefaults.standard.string(forKey: "KEY_USERNAME")
        if currentUsername != nil  {
            
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
            
            let gPath = "\(usernameHash)/" + currentUsername + "/g"
            let hPath = "\(usernameHash)/" + currentUsername + "/h"
            
            self.ref.child(gPath).observeSingleEvent(of: .value, with: { (snapshot) in
                
                let enumerator = snapshot.children
                while let item = enumerator.nextObject() as? DataSnapshot {
                    self.gList.append(item.key)
                }
                
                self.ref.child(hPath).observeSingleEvent(of: .value, with: { (snapshot) in
                    
                    let enumerator = snapshot.children
                    while let item = enumerator.nextObject() as? DataSnapshot {
                        self.gList.append(item.key)
                    }
                    
                    self.myCircleQuery()
                    
                }) { (error) in
                    print(error.localizedDescription)
                }
                
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    
    func myCircleQuery(){
        
        if fromIndex == 0 {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            queryTime = formatter.string(from: Date())
        }
        
        DispatchQueue.main.async {
            if !self.indicator.isAnimating && !self.refreshControl.isRefreshing {
                self.indicator.startAnimating()
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let payloadTime = formatter.string(from: Calendar.current.date(byAdding: .weekOfYear, value: -3, to: Date())!)
        
        //pick up to 25 random usernames from the gList, append that list of 25 with current username, then use that as the payload for the query
        var payload : String
        if !gList.isEmpty{
            var payloadArray : [String]
            if gList.count > 25 {
                payloadArray = gList.choose(25)
            }
            else {
                payloadArray = gList
            }
            
            var names = ""
            names.append("\"\(payloadArray[0])\"")
            if payloadArray.count > 1 {
                for i in 1...payloadArray.count-1 {
                    names.append(",\"\(payloadArray[i])\"")
                }
            }
            names.append(",\"\(currentUsername!)\"")
            
            payload = "{\"from\":\(fromIndex!),\"size\":\(retrievalSize),\"query\":{\"function_score\":{\"query\":{\"bool\":{\"should\":[{\"range\":{\"t\":{\"gt\":\"\(payloadTime)\",\"lte\":\"\(queryTime!)\"}}}]}},\"functions\":[{\"script_score\":{\"script\":\"doc[\'ci\'].value\"}},{\"filter\":{\"terms\":{\"a.keyword\":[\(names)]}},\"script_score\":{\"script\":\"10000\"}}],\"score_mode\":\"sum\"}}}"
        }
        else {
            print("payloadTime = \(payloadTime)")
            payload = "{\"from\":\(fromIndex!),\"size\":\(retrievalSize),\"query\":{\"function_score\":{\"query\":{\"bool\":{\"should\":[{\"range\":{\"t\":{\"gt\":\"\(payloadTime)\",\"lte\":\"\(queryTime!)\"}}}]}},\"functions\":[{\"script_score\":{\"script\":\"doc[\'ci\'].value\"}},{\"filter\":{\"terms\":{\"a.keyword\":[\"\(currentUsername!)\"]}},\"script_score\":{\"script\":\"10000\"}}],\"score_mode\":\"sum\"}}}"

        }
        
        //print("queryTime = \(queryTime!)")
        
        executeQuery(payload: payload)
        
    }
    
    func scrollOrRefresh() {
        if tableView != nil  && comments != nil && comments.count > 0 && !indicator.isAnimating {
            if tableView.contentOffset.y == 0.0 {
                refreshList(0)
                
            }
            else {
                tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
    }
    
    func executeQuery(payload : String){
        //debugLabel.text = "executing query"
        VSVersusAPIClient.default().commentslistGet(c: payload, d: nil, a: "nwv2", b: "\(fromIndex!)").continueWith(block:) {(task: AWSTask) -> AnyObject? in
            if task.error != nil {
                DispatchQueue.main.async {
                    print(task.error!)
                    //self.debugLabel.text = "debugDesc=\(task.error.debugDescription)\ndebugLocDesc=\(task.error?.localizedDescription)"
                }
            }
            else {
                /*
                DispatchQueue.main.async {
                    self.debugLabel.text = "api no error"
                }
                */
                
                let results = task.result?.hits?.hits
                var loadedItemsCount = results?.count
                var commentAuthors = ""
                
                if loadedItemsCount == 0 { //meaning no more items to load
                    self.nowLoading = true //this stops further loads
                    DispatchQueue.main.async {
                        if self.refreshControl.isRefreshing {
                            self.refreshControl.endRefreshing()
                        }
                        else {
                            self.indicator.stopAnimating()
                        }
                    }
                }
                else {
                    
                    var postInfoPayload = "{\"ids\":["
                    var index = 0
                    var duplicateUsernamePreventionMap = NSMutableSet()
                    var countToAdView = 0 //once this == adFrequency, we insert an add to the comments array
                    for item in results! {
                        let comment = VSComment(itemSource: item.source!, id: item.id!)
                        self.comments.append(comment)
                        
                        if !duplicateUsernamePreventionMap.contains(comment.author) {
                            commentAuthors.append("\"" + comment.author + "\",")
                            duplicateUsernamePreventionMap.add(comment.author)
                        }
                        
                        if self.postInfos[item.source!.pt!] == nil {
                            if index == 0 {
                                postInfoPayload.append("\""+item.source!.pt!+"\"")
                            }
                            else {
                                postInfoPayload.append(",\""+item.source!.pt!+"\"")
                            }
                            index += 1
                        }
                        
                        countToAdView += 1
                        if countToAdView == self.adFrequency {
                            //inserting a placeholder VSComment object for a native ad. Check for placeholder by checking if the object's commentID == "0"
                            self.comments.append(VSComment())
                            loadedItemsCount = loadedItemsCount! + 1
                            //should we randomize adFrequency? simply update its value here if we are.
                            
                        }
                        
                    }
                    postInfoPayload.append("]}")
                    
                    if index > 0 {
                        VSVersusAPIClient.default().postqmultiGet(a: "mpinfq", b: postInfoPayload).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                            if task.error != nil {
                                DispatchQueue.main.async {
                                    print(task.error!)
                                }
                            }
                            
                            if let results = task.result?.docs {
                                var postAuthors : Set<String> = []
                                
                                for item in results {
                                    self.postInfos[item.id!] = item.source
                                    if self.profileImageVersions[item.source!.a!] == nil {
                                        postAuthors.insert(item.source!.a!)
                                    }
                                }
                                
                                var pivPayload = "{\"ids\":["
                                var pivIndex = 0
                                if commentAuthors.count > 0 {
                                    pivPayload.append(commentAuthors)
                                }
                                for username in postAuthors {
                                    if username != "deleted" {
                                        if pivIndex == 0 {
                                            pivPayload.append("\""+username+"\"")
                                        }
                                        else {
                                            pivPayload.append(",\""+username+"\"")
                                        }
                                        pivIndex += 1
                                    }
                                }
                                
                                pivPayload.append("]}")
                                
                                if pivIndex > 0 {
                                    VSVersusAPIClient.default().pivGet(a: "pis", b: pivPayload).continueWith(block:) {(task: AWSTask) -> AnyObject? in
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
                                                    
                                                    let indexSet = IndexSet(self.fromIndex...self.fromIndex+loadedItemsCount!-1)
                                                    self.tableView.insertSections(indexSet, with: .fade)
                                                    
                                                    if self.refreshControl.isRefreshing {
                                                        self.refreshControl.endRefreshing()
                                                    }
                                                    else {
                                                        self.indicator.stopAnimating()
                                                    }
                                                }
                                            }
                                            if loadedItemsCount! < self.retrievalSize {
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
                                            let indexSet = IndexSet(self.fromIndex...self.fromIndex+loadedItemsCount!-1)
                                            self.tableView.insertSections(indexSet, with: .fade)
                                            
                                            if self.refreshControl.isRefreshing {
                                                self.refreshControl.endRefreshing()
                                            }
                                            else {
                                                self.indicator.stopAnimating()
                                            }
                                        }
                                    }
                                    if loadedItemsCount! < self.retrievalSize {
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
                                let indexSet = IndexSet(self.fromIndex...self.fromIndex+loadedItemsCount!-1)
                                self.tableView.insertSections(indexSet, with: .fade)
                                
                                if self.refreshControl.isRefreshing {
                                    self.refreshControl.endRefreshing()
                                }
                                else {
                                    self.indicator.stopAnimating()
                                }
                            }
                        }
                        if loadedItemsCount! < self.retrievalSize {
                            self.nowLoading = true
                        }
                        else {
                            self.nowLoading = false
                        }
                    }
                    
                }
            }
            return nil
        }
 
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let comment = comments[section]
        if hiddenSections.contains(comment.comment_id) || blockedUsernames.contains(comment.author) {
            return 0
        }
        else if let postInfo = postInfos[comment.post_id] {
            if self.blockedUsernames.contains(postInfo.a) {
                return 0
            }
            else {
                return cellSpacingHeight
            }
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
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastElement = comments.count - 1 - loadThreshold
        if !nowLoading && indexPath.section == lastElement {
            nowLoading = true
            fromIndex = comments.count
            myCircleQuery()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let comment = comments[indexPath.section]
        if hiddenSections.contains(comment.comment_id) || blockedUsernames.contains(comment.author) {
            return 0
        }
        else if let postInfo = postInfos[comment.post_id] {
            if self.blockedUsernames.contains(postInfo.a) {
                return 0
            }
            else {
                return UITableViewAutomaticDimension
            }
        }
        else {
            return UITableViewAutomaticDimension
        }
    }
    
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if expandedCells.contains(indexPath.section) {
            return 409
        }
        else {
            if comments[indexPath.section].comment_id != "0" {
                return 175
            }
            else {
                return 124
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentComment = comments[indexPath.section]
        
        if currentComment.comment_id != "0" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "vscard_mycircle", for: indexPath) as! MyCircleTableViewCell
            
            if let postInfo = postInfos[currentComment.post_id] {
                cell.setCell(comment: currentComment, postInfo: postInfo, row: indexPath.section)
                
                if let piv = profileImageVersions[postInfo.a!.lowercased()] {
                    cell.setProfileImage(username: postInfo.a!, profileImageVersion: piv)
                }
                else {
                    cell.setProfileImage(username: postInfo.a!, profileImageVersion: 0)
                }
                
            }
            else {
                cell.setCell(comment: currentComment, row: indexPath.section)
            }
            
            if let commentProfilePIV = profileImageVersions[currentComment.author.lowercased()] {
                cell.setCommentProfileImage(username: currentComment.author, profileImageVersion: commentProfilePIV)
            }
            else {
                cell.setCommentProfileImage(username: currentComment.author, profileImageVersion: 0)
            }
            
            cell.delegate = self
            
            if adjustForSmallerScreen {
                cell.replyButtonWidth.constant = 0
            }
            
            return cell
        }
        else { //native ad
            let mainVC = parent as! MCViewController
            var cell = UITableViewCell(style: .default, reuseIdentifier: "Native")
            mainVC.presentNative(onView: cell.contentView, fromIndex: indexPath as NSIndexPath, showMedia: false)
            return cell
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let clickedComment = comments[indexPath.section]
        
        if clickedComment.comment_id != "0" {
            if !clickLock {
                clickLock = true
                
                let mainVC = parent as! MCViewController
                
                var piv : Int!
                if let postInfo = postInfos[clickedComment.post_id] {
                    if let imageVersion = profileImageVersions[postInfo.a!.lowercased()] {
                        piv = imageVersion
                    }
                    else {
                        piv = 0
                    }
                }
                else {
                    piv = 0
                }
                
                mainVC.myCircleItemClick(comment: clickedComment, postProfileImage: piv)
            }
        }
        
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func beginUpdatesForSeeMore(row : Int) {
        expandedCells.add(row)
        tableView.beginUpdates()
    }
    
    func beginUpdates() {
        tableView.beginUpdates()
    }
    
    func endUpdates() {
        tableView.endUpdates()
    }
    
    func endUpdatesForSeeLess(row : Int) {
        tableView.endUpdates()
        expandedCells.remove(row)
    }
    
    func replyButtonTapped(row: Int) {
        if !clickLock {
            clickLock = true
            
            let mainVC = parent as! MCViewController
            let clickedComment = comments[row]
            var piv : Int!
            if let postInfo = postInfos[clickedComment.post_id] {
                if let imageVersion = profileImageVersions[postInfo.a!.lowercased()] {
                    piv = imageVersion
                }
                else {
                    piv = 0
                }
            }
            else {
                piv = 0
            }
            
            mainVC.myCircleItemClick(comment: clickedComment, postProfileImage: piv)
        }
    }
    
    func overflowTapped(commentID: String, sender: UIButton, rowNumber: Int) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.popoverPresentationController?.sourceView = sender
        alert.popoverPresentationController?.sourceRect = sender.bounds
        
        alert.addAction(UIAlertAction(title: "Hide", style: .default, handler: { _ in
            self.hiddenSections.add(commentID)
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: rowNumber)], with: .automatic)
            self.showToast(message: "Comment hidden.", length: 17)
        }))
        
        alert.addAction(UIAlertAction(title: "Report", style: .default, handler: { _ in
            // Prepare the popup assets
            let title = "Report this comment?"
            let message = ""
            
            // Create the dialog
            let popup = PopupDialog(title: title, message: message)
            
            // Create buttons
            let buttonOne = DefaultButton(title: "No", action: nil)
            
            // This button will not the dismiss the dialog
            let buttonTwo = DefaultButton(title: "Yes") {
                let commentReportPath = "reports/c/\(commentID)/"
                Database.database().reference().child(commentReportPath).setValue(true)
                self.showToast(message: "Comment reported.", length: 19)
            }
            
            popup.addButtons([buttonOne, buttonTwo])
            popup.buttonAlignment = .horizontal
            
            // Present dialog
            self.present(popup, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
        
        
        
    }
    
    func goToProfile(username: String) {
        if !clickLock {
            clickLock = true
            
            let mainVC = parent as! MCViewController
            
            mainVC.goToProfile(username: username)
        }
    }
    
    
    func prefetchProfileImage(indexPaths: [IndexPath]){
        print("hiho let's see if it's async")
        var imageRequests = [ImageRequest]()
        var index = 0
        for indexPath in indexPaths {
            let username = comments[indexPath.section].author
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
        
    }
    
}

extension Tab1CollectionViewController : IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "My Circle")
    }
}
