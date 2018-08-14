//
//  PostsHistoryViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/24/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class PostsHistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var posts = [PostObject]()
    var apiClient = VSVersusAPIClient.default()
    var fromIndex : Int!
    var nowLoading = false
    var loadThreshold = 2
    var retrievalSize = 20
    var currentUsername : String!
    var isMe : Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUpPostsHistory(username : String, thisIsMe : Bool) {
        fromIndex = 0
        posts.removeAll()
        currentUsername = username
        postsHistoryQuery(username: username)
    }
    
    func postsHistoryQuery(username : String){
        print("post history query called for \(fromIndex)")
        
        DispatchQueue.main.async {
            self.indicator.startAnimating()
        }
        
        apiClient.postslistcompactGet(c: username, a: "pp", b: "\(fromIndex!)").continueWith(block:) {(task: AWSTask) -> AnyObject? in
            if task.error != nil {
                DispatchQueue.main.async {
                    print(task.error!)
                }
            }
            else {
                if let results = task.result!.hits!.hits {
                    
                    for item in results {
                        self.posts.append(PostObject(compactSource: item.source!, id: item.id!))
                    }
                    if results.count > 0 {
                        if self.fromIndex == 0 {
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                                self.indicator.stopAnimating()
                            }
                        }
                        else {
                            var indexPaths = [IndexPath]()
                            for i in 0...results.count-1 {
                                indexPaths.append(IndexPath(row: self.fromIndex + i, section: 0))
                            }
                            DispatchQueue.main.async {
                                self.tableView.insertRows(at: indexPaths, with: .fade)
                                self.indicator.stopAnimating()
                            }
                        }
                        if results.count < self.retrievalSize {
                            self.nowLoading = true
                        }
                        else {
                            self.nowLoading = false
                        }
                        
                    }
                    else {
                        DispatchQueue.main.async {
                            self.nowLoading = true
                            self.indicator.stopAnimating()
                        }
                    }
                    
                }
                else {
                    DispatchQueue.main.async {
                        self.nowLoading = true
                        self.indicator.stopAnimating()
                    }
                }
            }
            return nil
        }
        
        
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if isMe {
            let meVC = parent as! MeViewController
            meVC.handlePostsHistoryClick(post: posts[indexPath.row])
        }
        else {
            let profileVC = parent as! ProfileViewController
            profileVC.handlePostsHistoryClick(post: posts[indexPath.row])
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
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
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastElement = posts.count - 1 - loadThreshold
        if !nowLoading && indexPath.row == lastElement {
            nowLoading = true
            fromIndex = posts.count
            postsHistoryQuery(username: currentUsername!)
        }
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostsHistoryItem", for: indexPath) as? PostsHistoryTableViewCell
        cell!.setCell(post: posts[indexPath.row])
        return cell!
    }

}

extension PostsHistoryViewController : IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "POSTS")
    }
}
