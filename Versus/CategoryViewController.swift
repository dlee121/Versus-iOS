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

class CategoryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    var fromIndex = 0
    let DEFAULT = 0
    let S3 = 1
    let apiClient = VSVersusAPIClient.default()
    var posts = [PostObject]()
    var vIsRed = true
    let preheater = Nuke.ImagePreheater()
    var profileImageVersions = [String : Int]()
    
    var screenWidth : CGFloat!
    var textsVSCHeight : CGFloat!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        screenWidth = self.view.frame.size.width
        textsVSCHeight = screenWidth / 1.6
        
        // Do any additional setup after loading the view.
    }
    
    
    func categoryQuery(fromIndex : Int, category : Int){
        self.apiClient.postslistGet(c: "\(category)", d: "t", a: "ct", b: "\(fromIndex)").continueWith(block:) {(task: AWSTask) -> AnyObject? in
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
                                    self.collectionView.reloadData()
                                }
                            }
                            else {
                                DispatchQueue.main.async {
                                    let newIndexPath = IndexPath(row: fromIndex, section: 0)
                                    self.collectionView.insertItems(at: [newIndexPath])
                                }
                            }
                            
                            self.fromIndex = results.count - 1
                            
                        }
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
            return CGSize(width: screenWidth, height: screenWidth)
        }
        else {
            return CGSize(width: screenWidth, height: textsVSCHeight)
        }
        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("cellForItemAt called for \(indexPath.row)")
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
    
}
