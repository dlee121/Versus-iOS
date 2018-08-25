//
//  CommentsHistoryViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/24/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class CommentsHistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var comments = [VSComment]()
    var postInfoMap = [String : PostInfo]()
    var apiClient = VSVersusAPIClient.default()
    var fromIndex : Int!
    var nowLoading = false
    var loadThreshold = 2
    var currentUsername : String!
    var retrievalSize = 20
    var isMe : Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUpCommentsHistory(username : String, thisIsMe : Bool) {
        isMe = thisIsMe
        fromIndex = 0
        currentUsername = username
        comments.removeAll()
        commentsHistoryQuery(username: username)
    }
    
    func commentsHistoryQuery(username : String){
        
        DispatchQueue.main.async {
            self.indicator.startAnimating()
        }
        
        apiClient.commentslistGet(c: username, d: nil, a: "pc", b: "\(fromIndex!)").continueWith(block:) {(task: AWSTask) -> AnyObject? in
            if task.error != nil {
                DispatchQueue.main.async {
                    print(task.error!)
                }
            }
            else {
                if let queryResults = task.result!.hits!.hits {
                    
                    if queryResults.count > 1 {
                        var payload = "{\"ids\":["
                        var index = 0
                        
                        for item in queryResults {
                            self.comments.append(VSComment(itemSource: item.source!, id: item.id!))
                            if index == 0 {
                                if self.postInfoMap[item.source!.pt!] == nil {
                                    payload.append("\""+item.source!.pt!+"\"")
                                }
                            }
                            else {
                                if self.postInfoMap[item.source!.pt!] == nil {
                                    payload.append(",\""+item.source!.pt!+"\"")
                                }
                            }
                            index += 1
                        }
                        payload.append("]}")
                        
                        self.apiClient.postinfomultiGet(a: "mpinf", b: payload).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                            
                            if let pinfResults = task.result?.docs {
                                for pinfItem in pinfResults {
                                    self.postInfoMap[pinfItem.id!] = PostInfo(itemSource: pinfItem.source!)
                                }
                            }
                            
                            
                            
                            if self.comments.count < self.retrievalSize {
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                    self.indicator.stopAnimating()
                                }
                            }
                            else {
                                var indexPaths = [IndexPath]()
                                for i in 0...queryResults.count-1 {
                                    indexPaths.append(IndexPath(row: self.fromIndex + i, section: 0))
                                }
                                DispatchQueue.main.async {
                                    self.tableView.insertRows(at: indexPaths, with: .fade)
                                    self.indicator.stopAnimating()
                                }
                            }
                            
                            if queryResults.count < self.retrievalSize {
                                self.nowLoading = true
                            }
                            else {
                                self.nowLoading = false
                            }
                            
                            return nil
                        }
                    }
                    else if queryResults.count == 1 {
                        self.nowLoading = true
                        let source = queryResults[0].source!
                        self.comments.append(VSComment(itemSource: source, id: queryResults[0].id!))
                        self.fromIndex = self.comments.count
                        
                        self.apiClient.postinfoGet(a: "pinf", b: source.pt).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                            if let pinfResult = task.result {
                                self.postInfoMap[queryResults[0].id!] = PostInfo(itemSource: pinfResult)
                            }
                            if self.comments.count < self.retrievalSize {
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                    self.indicator.stopAnimating()
                                }
                            }
                            else {
                                var indexPaths = [IndexPath]()
                                for i in 0...queryResults.count-1 {
                                    indexPaths.append(IndexPath(row: self.fromIndex + i, section: 0))
                                }
                                DispatchQueue.main.async {
                                    self.tableView.insertRows(at: indexPaths, with: .fade)
                                    self.indicator.stopAnimating()
                                }
                            }
                            
                            if queryResults.count < self.retrievalSize {
                                self.nowLoading = true
                            }
                            else {
                                self.nowLoading = false
                            }
                            
                            return nil
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            self.nowLoading = true
                            self.indicator.stopAnimating()
                        }
                    }
                }
            }
            return nil
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastElement = comments.count - 1 - loadThreshold
        if !nowLoading && indexPath.row == lastElement {
            nowLoading = true
            fromIndex = comments.count
            commentsHistoryQuery(username: currentUsername!)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if isMe {
            let meVC = parent as! MeViewController
            meVC.handleCommentsHistoryClick(commentID: comments[indexPath.row].comment_id)
        }
        else {
            let profileVC = parent as! ProfileViewController
            profileVC.handleCommentsHistoryClick(commentID: comments[indexPath.row].comment_id)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentsHistoryItem", for: indexPath) as? CommentsHistoryTableViewCell
        let comment = comments[indexPath.row]
        cell!.setCell(comment: comment, postInfo: postInfoMap[comment.post_id])
        return cell!
    }
}


extension CommentsHistoryViewController : IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "COMMENTS")
    }
}
