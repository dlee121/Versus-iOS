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

    var comments = [VSComment]()
    var postInfoMap = [String : PostInfo]()
    var apiClient = VSVersusAPIClient.default()
    var fromIndex : Int!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUpCommentsHistory(username : String) {
        fromIndex = 0
        comments.removeAll()
        commentsHistoryQuery(username: username)
    }
    
    func commentsHistoryQuery(username : String){
        apiClient.commentslistGet(c: username, d: nil, a: "pc", b: "\(fromIndex!)").continueWith(block:) {(task: AWSTask) -> AnyObject? in
            if task.error != nil {
                DispatchQueue.main.async {
                    print(task.error!)
                }
            }
            else {
                if let results = task.result!.hits!.hits {
                    
                    if results.count > 1 {
                        var payload = "{\"ids\":["
                        var index = 0
                        
                        for item in results {
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
                        self.fromIndex = self.comments.count
                        self.apiClient.postinfomultiGet(a: "mpinf", b: payload).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                            
                            if let pinfResults = task.result?.docs {
                                for pinfItem in pinfResults {
                                    self.postInfoMap[pinfItem.id!] = PostInfo(itemSource: pinfItem.source!)
                                }
                            }
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                            return nil
                        }
                    }
                    else if results.count == 1 {
                        let source = results[0].source!
                        self.comments.append(VSComment(itemSource: source, id: results[0].id!))
                        self.fromIndex = self.comments.count
                        
                        self.apiClient.postinfoGet(a: "pinf", b: source.pt).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                            if let pinfResult = task.result {
                                self.postInfoMap[results[0].id!] = PostInfo(itemSource: pinfResult)
                            }
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                            
                            return nil
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
    
    /*
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if(indexPath.row == 0){
            return CGFloat(116.0)
        }
        return CGFloat(102.0)
    }
    */
    
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
