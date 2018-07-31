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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        screenWidth = self.view.frame.size.width
        textsVSCHeight = screenWidth / 1.6
        if comments.count == 0 {
            myCircleInitialSetup()
        }
        
        
        // Do any additional setup after loading the view.
    }
    
    func myCircleInitialSetup(){
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
                
                self.ref.child(gPath).observeSingleEvent(of: .value, with: { (snapshot) in
                    
                    let enumerator = snapshot.children
                    while let item = enumerator.nextObject() as? DataSnapshot {
                        self.gList.append(item.key)
                    }
                    
                    self.myCircleQuery()
                    
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
        print("payload: "+payload)
        
        self.apiClient.commentslistGet(c: payload, d: nil, a: "nwv2", b: "\(fromIndex!)").continueWith(block:) {(task: AWSTask) -> AnyObject? in
            if task.error != nil {
                DispatchQueue.main.async {
                    print(task.error!)
                }
            }
            else {
                let results = task.result?.hits?.hits
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
                    }
                    
                    index += 1
                }
                postInfoPayload += "]}"
                
                self.apiClient.postqmultiGet(a: "mpinfq", b: postInfoPayload).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                    if task.error != nil {
                        DispatchQueue.main.async {
                            print(task.error!)
                        }
                    }
                    
                    if let results = task.result?.docs {
                        for item in results {
                            self.postInfos[item.id!] = item.source
                        }
                        
                        if self.fromIndex == 0 {
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
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
                    
                    return nil
                }
                
                
            }
            return nil
        }
 
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    /*
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let comment = comments[indexPath.row]
        if post.redimg.intValue % 10 == S3 || post.blackimg.intValue % 10 == S3 {
            return CGSize(width: screenWidth, height: screenWidth)
        }
        else {
            return CGSize(width: screenWidth, height: textsVSCHeight)
        }
    }
    */
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentComment = comments[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "vscard_mycircle", for: indexPath) as! MyCircleTableViewCell
        
        if let postInfo = postInfos[currentComment.post_id] {
            cell.setCell(comment: currentComment, postInfo: postInfo)
        }
        else {
            cell.setCell(comment: currentComment)
        }
        
        return cell
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
