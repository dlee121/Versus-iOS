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

class MCViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSourcePrefetching {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var fromIndex = 0
    let DEFAULT = 0
    let S3 = 1
    
    var posts = [PostObject]()
    var vIsRed = true
    let preheater = Nuke.ImagePreheater()
    var profileImageVersions = [String : Int]()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if posts.count == 0 {
            trendingQuery(fromIndex: 0)
        }
        
 
        // Do any additional setup after loading the view.
    }
    
    
    func trendingQuery(fromIndex : Int){
        VSVersusAPIClient.default().postslistGet(c: nil, d: nil, a: "tr", b: "\(fromIndex)").continueWith(block:) {(task: AWSTask) -> AnyObject? in
            if task.error != nil {
                DispatchQueue.main.async {
                    print(task.error!)
                }
            }
            else {
                let results = task.result?.hits?.hits
                var pivString = "{\"ids\":["
                var index = 0
                for item in results! {
                    self.posts.append(PostObject(itemSource: item.source!, id: item.id!))
                    
                    if item.source?.a != "deleted" {
                        if index == 0 {
                            pivString += "\"" + item.source!.a! + "\""
                        }
                        else {
                            pivString += ",\"" + item.source!.a! + "\""
                        }
                    }
                    
                    index += 1
                }
                pivString += "]}"
                
                print(pivString)
                
                VSVersusAPIClient.default().pivGet(a: "pis", b: pivString.lowercased()).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                    if task.error != nil {
                        DispatchQueue.main.async {
                            print(task.error!)
                        }
                    }
                    
                    let results = task.result?.docs
                    
                    for item in results! {
                        self.profileImageVersions[item.id!] = item.source?.pi?.intValue
                    }
                    
                    if index > 0 {
                        if fromIndex == 0 {
                            DispatchQueue.main.async {
                                self.collectionView.reloadData()
                            }
                        }
                        else {
                            DispatchQueue.main.async {
                                let newIndexPath = IndexPath(row: fromIndex, section: 0)
                                self.collectionView.insertItems(at: [newIndexPath])
                            }
                        }
                        
                        self.fromIndex = results!.count - 1
                        
                    }
                    
                    return nil
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
            return CGSize(width: 343, height: 340)
        }
        else {
            return CGSize(width: 343, height: 213)
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
            
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "vscard_texts", for: indexPath) as! PostTextCollectionViewCell
            cell.setCell(post: currentPost, vIsRed: vIsRed)
            vIsRed = !vIsRed
            
            return cell
        }
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        
    }
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logOutTapped(_ sender: UIButton) {
        //remove session data, log out firebase user, then segue back to start screen
        UserDefaults.standard.removeObject(forKey: "KEY_BDAY")
        UserDefaults.standard.removeObject(forKey: "KEY_EMAIL")
        UserDefaults.standard.removeObject(forKey: "KEY_USERNAME")
        UserDefaults.standard.removeObject(forKey: "KEY_PI")
        UserDefaults.standard.removeObject(forKey: "KEY_IS_NATIVE")
        try! Auth.auth().signOut()
        performSegue(withIdentifier: "logOutToStart", sender: self)
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
