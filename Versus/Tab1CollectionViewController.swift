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
import FirebaseDatabase

class Tab1CollectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    var fromIndex : Int!
    let DEFAULT = 0
    let S3 = 1
    let apiClient = VSVersusAPIClient.default()
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
    
    var clickLock = false
    
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        //refresh the list
        //refreshControl.endRefreshing()
        comments.removeAll()
        tableView.reloadData()
        myCircleInitialSetup()
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
        if !refreshControl.isRefreshing {
            indicator.startAnimating()
        }
        
        fromIndex = 0
        var usernameHash : Int32
        currentUsername = UserDefaults.standard.string(forKey: "KEY_USERNAME")
        if currentUsername != nil  {
            
            if gList.isEmpty {
                
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
            else {
                myCircleQuery()
            }
        }
    }
    
    func myCircleQuery(){
        
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
            
            payload = "{\"from\":\(fromIndex!),\"size\":\(retrievalSize),\"query\":{\"function_score\":{\"query\":{\"bool\":{\"should\":[{\"range\":{\"t\":{\"gt\":\"\(payloadTime)\"}}}]}},\"functions\":[{\"script_score\":{\"script\":\"doc[\'ci\'].value\"}},{\"filter\":{\"terms\":{\"a.keyword\":[\(names)]}},\"script_score\":{\"script\":\"10000\"}}],\"score_mode\":\"sum\"}}}"
        }
        else {
            payload = "{\"from\":\(fromIndex!),\"size\":\(retrievalSize),\"query\":{\"function_score\":{\"query\":{\"bool\":{\"should\":[{\"range\":{\"t\":{\"gt\":\"\(payloadTime)\"}}}]}},\"functions\":[{\"script_score\":{\"script\":\"doc[\'ci\'].value\"}},{\"filter\":{\"terms\":{\"a.keyword\":[\"\(currentUsername!)\"]}},\"script_score\":{\"script\":\"10000\"}}],\"score_mode\":\"sum\"}}}"

        }
        
        executeQuery(payload: payload)
        
    }
    
    func executeQuery(payload : String){
        
        self.apiClient.commentslistGet(c: payload, d: nil, a: "nwv2", b: "\(fromIndex!)").continueWith(block:) {(task: AWSTask) -> AnyObject? in
            if task.error != nil {
                DispatchQueue.main.async {
                    print(task.error!)
                }
            }
            else {
                let results = task.result?.hits?.hits
                let loadedItemsCount = results?.count
                
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
                    for item in results! {
                        self.comments.append(VSComment(itemSource: item.source!, id: item.id!))
                        
                        if self.postInfos[item.source!.pt!] == nil {
                            if index == 0 {
                                postInfoPayload.append("\""+item.source!.pt!+"\"")
                            }
                            else {
                                postInfoPayload.append(",\""+item.source!.pt!+"\"")
                            }
                            index += 1
                        }
                        
                        
                    }
                    postInfoPayload.append("]}")
                    
                    if index > 0 {
                        self.apiClient.postqmultiGet(a: "mpinfq", b: postInfoPayload).continueWith(block:) {(task: AWSTask) -> AnyObject? in
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
                                    self.apiClient.pivGet(a: "pis", b: pivPayload).continueWith(block:) {(task: AWSTask) -> AnyObject? in
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
                                                    var indexPaths = [IndexPath]()
                                                    for i in 0...loadedItemsCount!-1 {
                                                        indexPaths.append(IndexPath(row: self.fromIndex+i, section: 0))
                                                    }
                                                    
                                                    self.tableView.insertRows(at: indexPaths, with: .fade)
                                                    
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
                                            var indexPaths = [IndexPath]()
                                            for i in 0...loadedItemsCount!-1 {
                                                indexPaths.append(IndexPath(row: self.fromIndex+i, section: 0))
                                            }
                                            
                                            self.tableView.insertRows(at: indexPaths, with: .fade)
                                            
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
                                var indexPaths = [IndexPath]()
                                for i in 0...loadedItemsCount!-1 {
                                    indexPaths.append(IndexPath(row: self.fromIndex+i, section: 0))
                                }
                                
                                self.tableView.insertRows(at: indexPaths, with: .fade)
                                
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
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastElement = comments.count - 1 - loadThreshold
        if !nowLoading && indexPath.row == lastElement {
            nowLoading = true
            fromIndex = comments.count
            myCircleQuery()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentComment = comments[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "vscard_mycircle", for: indexPath) as! MyCircleTableViewCell
        
        if let postInfo = postInfos[currentComment.post_id] {
            cell.setCell(comment: currentComment, postInfo: postInfo)
            
            if let piv = profileImageVersions[postInfo.a!.lowercased()] {
                cell.setProfileImage(username: postInfo.a!, profileImageVersion: piv)
            }
            else {
                cell.setProfileImage(username: postInfo.a!, profileImageVersion: 0)
            }
        }
        else {
            cell.setCell(comment: currentComment)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if !clickLock {
            clickLock = true
            
            let mainVC = parent as! MCViewController
            let clickedComment = comments[indexPath.row]
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
    
    
    
    func prefetchProfileImage(indexPaths: [IndexPath]){
        print("hiho let's see if it's async")
        var imageRequests = [ImageRequest]()
        var index = 0
        for indexPath in indexPaths {
            let username = comments[indexPath.row].author
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
    
}

extension Tab1CollectionViewController : IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "My Circle")
    }
}
