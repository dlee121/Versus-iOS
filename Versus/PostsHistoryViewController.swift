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

    var posts = [PostObject]()
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
    
    func setUpPostsHistory(username : String) {
        fromIndex = 0
        posts.removeAll()
        postsHistoryQuery(username: username)
    }
    
    func postsHistoryQuery(username : String){
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
                    self.fromIndex = self.posts.count
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
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
        return posts.count
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
