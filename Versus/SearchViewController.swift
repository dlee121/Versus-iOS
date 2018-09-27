//
//  SearchViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/16/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchResultsUpdating {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var fromIndex = 0
    let DEFAULT = 0
    let S3 = 1
    var posts = [PostObject]()
    var profileImageVersions = [String : Int]()
    var nowLoading = false
    var retrievalSize = 16
    var loadThreshold = 6
    var currentInput : String!
    var mainContainer : MCViewController!
    var currentSearchTerm = ""
    
    var clickLock = false
    
    var searchVersion = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func searchThis(input : String){
        posts.removeAll()
        fromIndex = 0
        tableView.reloadData()
        if !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            currentInput = input
            searchExecute(input: input, index: fromIndex)
        }
        
    }
    
    func searchExecute(input : String, index : Int){
        searchVersion += 1
        let thisSearchVersion = searchVersion
        print("execute search")
        DispatchQueue.main.async {
            self.indicator.startAnimating()
        }
        
        guard thisSearchVersion == self.searchVersion else {
            return
        }
        
        VSVersusAPIClient.default().postslistcompactGet(c: input, a: "sp", b: "\(index)").continueWith(block:) {(task: AWSTask) -> AnyObject? in
            if thisSearchVersion != self.searchVersion {
                return nil
            }
            
            
            if task.error != nil {
                DispatchQueue.main.async {
                    print(task.error!)
                }
            }
            else {
                let queryResults = task.result?.hits?.hits
                if !queryResults!.isEmpty{
                    
                    if thisSearchVersion != self.searchVersion {
                        return nil
                    }
                    
                    var pivString = "{\"ids\":["
                    var index = 0
                    for item in queryResults! {
                        self.posts.append(PostObject(compactSource: item.source!, id: item.id!))
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
                    
                    if thisSearchVersion != self.searchVersion {
                        return nil
                    }
                    
                    //this effectively means that if the search result only contains deleted posts, it won't show the results. maybe change that in future updates.
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
                                
                                if thisSearchVersion != self.searchVersion {
                                    return nil
                                }
                                
                                if self.fromIndex == 0 {
                                    DispatchQueue.main.async {
                                        self.tableView.reloadData()
                                        self.indicator.stopAnimating()
                                    }
                                }
                                else {
                                    DispatchQueue.main.async {
                                        var indexPaths = [IndexPath]()
                                        for i in 0...queryResults!.count-1{
                                            indexPaths.append(IndexPath(row: self.fromIndex+i, section: 0))
                                        }
                                        
                                        self.tableView.insertRows(at: indexPaths, with: .fade)
                                        self.indicator.stopAnimating()
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
                        self.nowLoading = true
                        DispatchQueue.main.async {
                            self.indicator.stopAnimating()
                        }
                    }
                }
                else {
                    self.nowLoading = true
                    DispatchQueue.main.async {
                        self.indicator.stopAnimating()
                    }
                }
            }
            return nil
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastElement = posts.count - 1 - loadThreshold
        if !nowLoading && indexPath.row == lastElement {
            nowLoading = true
            fromIndex = posts.count
            searchExecute(input: currentInput, index: fromIndex)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentPost = posts[indexPath.row]
        
        //set profile image version for the post if one exists
        if let piv = profileImageVersions[currentPost.author.lowercased()] {
            currentPost.setProfileImageVersion(piv: piv)
        }
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchPostCell", for: indexPath) as! SearchPostTableViewCell
        cell.setCell(post: posts[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if !clickLock {
            clickLock = true
            VSVersusAPIClient.default().postGet(a: "p", b: posts[indexPath.row].post_id).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                if task.error != nil {
                    DispatchQueue.main.async {
                        print(task.error!)
                    }
                }
                else {
                    if let postResult = task.result {
                        var clickedPost = PostObject(itemSource: postResult.source!, id: postResult.id!)
                        DispatchQueue.main.async {
                            self.mainContainer.goToPostPageRoot(post: clickedPost)
                        }
                    }
                }
                return nil
            }
        }
    }
    
    
    func updateSearchResults(for searchController: UISearchController) {
        
        guard let searchText = searchController.searchBar.text else { return }
        if searchText != currentSearchTerm {
            searchThis(input: searchText)
        }
        currentSearchTerm = searchText
        
        clickLock = false
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
