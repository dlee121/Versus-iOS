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
    
    var fromIndex = 0
    let DEFAULT = 0
    let S3 = 1
    let apiClient = VSVersusAPIClient.default()
    var results = [PostObject]()
    var profileImageVersions = [String : Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func searchThis(input : String){
        results.removeAll()
        fromIndex = 0
        tableView.reloadData()
        if !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            searchExecute(input: input, index: fromIndex)
        }
        
    }
    
    func searchExecute(input : String, index : Int){
        print("search executed")
        self.apiClient.postslistcompactGet(c: input, a: "sp", b: "\(index)").continueWith(block:) {(task: AWSTask) -> AnyObject? in
            if task.error != nil {
                DispatchQueue.main.async {
                    print(task.error!)
                }
            }
            else {
                let results = task.result?.hits?.hits
                if !results!.isEmpty{
                    var pivString = "{\"ids\":["
                    var index = 0
                    for item in results! {
                        self.results.append(PostObject(compactSource: item.source!, id: item.id!))
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
                    
                    //print(pivString)
                    
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
                            
                            if index > 0 {
                                if self.fromIndex == 0 {
                                    DispatchQueue.main.async {
                                        print("all the way here")
                                        self.tableView.reloadData()
                                        print("then here")
                                    }
                                }
                                else {
                                    DispatchQueue.main.async {
                                        let newIndexPath = IndexPath(row: self.fromIndex, section: 0)
                                        self.tableView.insertRows(at: [newIndexPath], with: .automatic)
                                    }
                                }
                                
                                self.fromIndex = results.count - 1
                                
                            }
                        }
                        
                        
                        
                        return nil
                    }
                }
                
            }
            return nil
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentPost = results[indexPath.row]
        
        //set profile image version for the post if one exists
        if let piv = profileImageVersions[currentPost.author.lowercased()] {
            currentPost.setProfileImageVersion(piv: piv)
        }
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchPostCell", for: indexPath) as! SearchPostTableViewCell
        cell.setCell(post: results[indexPath.row])
        return cell
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        searchThis(input: searchText)
        
        
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
