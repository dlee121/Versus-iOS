//
//  RootPageViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 8/3/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit


class RootPageViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PostPageDelegator {

    @IBOutlet weak var tableView: UITableView!
    
    var currentPost : PostObject!
    var comments = [VSComment]()
    let apiClient = VSVersusAPIClient.default()
    var rootComments = [VSComment]()
    var childComments = [VSComment]()
    var grandchildComments = [VSComment]()
    var nodeMap = [String : VSCNode]()
    var currentUserAction : UserAction!
    var tappedUsername : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.allowsSelection = false
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //hidesBottomBarWhenPushed = true
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if currentUserAction.changed {
            //update UserAction in ES
            apiClient.recordPost(body: currentUserAction.getRecordPutModel(), a: "rcp", b: currentUserAction.id)
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUpRootPage(post : PostObject, userAction : UserAction){
        comments.removeAll()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        currentPost = post
        comments.append(VSComment()) //placeholder for post object
        currentUserAction = userAction
        commentsQuery()
        
    }
    
    func commentsQuery(){
        
        //get the root comments, children, and grandchildren
        apiClient.commentslistGet(c: currentPost.post_id, d: nil, a: "rci", b: "0").continueWith(block:) {(task: AWSTask) -> AnyObject? in
            
            if task.error != nil {
                DispatchQueue.main.async {
                    print(task.error!)
                }
            }
            else {
                if let rootQueryResults = task.result?.hits?.hits {
                    var rootIndex = 0
                    var prevNode : VSCNode?
                    var cqPayload = ""
                    var cqPayloadIndex = 0
                    for item in rootQueryResults {
                        let comment = VSComment(itemSource: item.source!, id: item.id!)
                        comment.nestedLevel = 0
                        self.rootComments.append(comment)
                        
                        //set up node structure with current root comment
                        if rootIndex == 0 {
                            prevNode = VSCNode(comment: comment)
                            self.nodeMap[comment.comment_id] = prevNode
                        }
                        else {
                            let currNode = VSCNode(comment: comment)
                            prevNode?.tailSibling = currNode
                            currNode.headSibling = prevNode
                            self.nodeMap[comment.comment_id] = currNode
                        }
                        
                        rootIndex += 1
                        
                        //build payload for child comment query
                        if cqPayloadIndex == 0 {
                            cqPayload.append(comment.comment_id)
                        }
                        else {
                            cqPayload.append(","+comment.comment_id)
                        }
                        
                        cqPayloadIndex += 1
                    }
                    
                    if cqPayloadIndex > 0 {
                        
                        //child comments query
                        self.apiClient.cgcGet(a: "cgc", b: cqPayload).continueWith(block:) {(cqTask: AWSTask) -> AnyObject? in
                            if cqTask.error != nil {
                                DispatchQueue.main.async {
                                    print(cqTask.error!)
                                }
                            }
                            else {
                                if let cqResponses = cqTask.result?.responses {
                                    var rIndex = 0
                                    var gcqPayload = ""
                                    var gcqPayloadIndex = 0
                                    
                                    for cqResponseItem in cqResponses {
                                        let cqHitsObject = cqResponseItem.hits
                                        let currentRoot = self.rootComments[rIndex]
                                        currentRoot.child_count = cqHitsObject?.total!.intValue //set child count for parent root comment
                                        let rootNode = self.nodeMap[currentRoot.comment_id]
                                        var prevNode : VSCNode?
                                        for cqCommentItem in cqResponseItem.hits!.hits! {
                                            
                                            let childComment = VSComment(itemSource: cqCommentItem.source!, id: cqCommentItem.id!)
                                            childComment.nestedLevel = 1
                                            self.childComments.append(childComment)
                                            
                                            //set up node structure with current child comment
                                            if prevNode == nil {
                                                prevNode = VSCNode(comment: childComment)
                                                rootNode?.firstChild = prevNode
                                                prevNode?.parent = rootNode
                                                self.nodeMap[childComment.comment_id] = prevNode
                                            }
                                            else {
                                                let currNode = VSCNode(comment: childComment)
                                                prevNode?.tailSibling = currNode
                                                currNode.headSibling = prevNode
                                                self.nodeMap[childComment.comment_id] = currNode
                                            }
                                            
                                            //build payload for grandchild query
                                            if gcqPayloadIndex == 0 {
                                                gcqPayload.append(childComment.comment_id)
                                            }
                                            else {
                                                gcqPayload.append(","+childComment.comment_id)
                                            }
                                            
                                            gcqPayloadIndex += 1
                                            
                                        }
                                        rIndex += 1
                                    }
                                    
                                    if gcqPayloadIndex > 0 {
                                        
                                        //grandchild comments query
                                        self.apiClient.cgcGet(a: "cgc", b: gcqPayload).continueWith(block:) {(gcqTask: AWSTask) -> AnyObject? in
                                            if gcqTask.error != nil {
                                                DispatchQueue.main.async {
                                                    print(gcqTask.error!)
                                                }
                                            }
                                            else {
                                                if let gcqResponses = gcqTask.result?.responses {
                                                    var cIndex = 0
                                                    for gcqResponseItem in gcqResponses {
                                                        let gcqHitsObject = gcqResponseItem.hits
                                                        let currentParent = self.childComments[cIndex]
                                                        currentParent.child_count = gcqHitsObject?.total!.intValue //set child count for parent child comment
                                                        let parentNode = self.nodeMap[currentParent.comment_id]
                                                        var prevNode : VSCNode?
                                                        for gcqCommentItem in gcqResponseItem.hits!.hits! {
                                                            
                                                            let grandchildComment = VSComment(itemSource: gcqCommentItem.source!, id: gcqCommentItem.id!)
                                                            grandchildComment.nestedLevel = 2
                                                            self.grandchildComments.append(grandchildComment)
                                                            
                                                            if prevNode == nil {
                                                                prevNode = VSCNode(comment: grandchildComment)
                                                                parentNode?.firstChild = prevNode
                                                                prevNode?.parent = parentNode
                                                                self.nodeMap[grandchildComment.comment_id] = prevNode
                                                            }
                                                            else {
                                                                let currNode = VSCNode(comment: grandchildComment)
                                                                prevNode?.tailSibling = currNode
                                                                currNode.headSibling = prevNode
                                                                self.nodeMap[grandchildComment.comment_id] = currNode
                                                            }
                                                        }
                                                        cIndex += 1
                                                    }
                                                }
                                                //sets the comments list for tableView using the nodeMap
                                                self.setComments()
                                            }
                                            return nil
                                        }
                                    }
                                    else { //no child comments
                                        self.setComments()
                                    }
                                }
                            }
                            return nil
                        }
                    }
                    else { //no root comments
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
            }
            return nil
        }
    }
    
    
    
    func setComments(){
        for i in 0...rootComments.count-1{
            let currentRootNode = nodeMap[rootComments[i].comment_id]
            comments.append(currentRootNode!.nodeContent)
            
            if let firstChild = currentRootNode?.firstChild {
                comments.append(firstChild.nodeContent)
                
                if let firstGrandchild = firstChild.firstChild {
                    comments.append(firstGrandchild.nodeContent)
                    
                    if let secondGrandchild = firstGrandchild.tailSibling {
                        comments.append(secondGrandchild.nodeContent)
                    }
                }
                
                if let secondChild = firstChild.tailSibling {
                    comments.append(secondChild.nodeContent)
                    
                    if let firstGrandchild = firstChild.firstChild {
                        comments.append(firstGrandchild.nodeContent)
                        
                        if let secondGrandchild = firstGrandchild.tailSibling {
                            comments.append(secondGrandchild.nodeContent)
                        }
                    }
                }
            }
            
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 { //for RootPage, first item of the comments list is a placeholder for the post object
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostCard", for: indexPath) as? PostCardTableViewCell
            cell!.setCell(post: currentPost, votedSide: currentUserAction.votedSide)
            cell!.delegate = self
            return cell!
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCard", for: indexPath) as? CommentCardTableViewCell
            let comment = comments[indexPath.row]
            if let selection = currentUserAction.actionRecord[comment.comment_id] {
                switch selection {
                case "N":
                    cell!.setCell(comment: comment, indent: comment.nestedLevel!)
                case "U":
                    cell!.setCellWithSelection(comment: comment, indent: comment.nestedLevel!, hearted: true)
                case "D":
                    cell!.setCellWithSelection(comment: comment, indent: comment.nestedLevel!, hearted: false)
                default:
                    cell!.setCell(comment: comment, indent: comment.nestedLevel!)
                }
            }
            else {
                cell!.setCell(comment: comment, indent: comment.nestedLevel!)
            }
            cell!.delegate = self
            
            return cell!
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let profileVC = segue.destination as? ProfileViewController else {return}
        profileVC.currentUsername = tappedUsername!
        
    }
    
    func callSegueFromCell(profileUsername: String) {
        tappedUsername = profileUsername
        //try not to send self, just to avoid retain cycles(depends on how you handle the code on the next controller)
        performSegue(withIdentifier: "rootToProfile", sender: self)
    }
    
    func resizePostCardOnVote(red : Bool){
        if currentUserAction.votedSide == "none" {
            //this is a new vote; send notification to author
            
        }
        
        if red {
            currentUserAction.votedSide = "RED"
        }
        else {
            currentUserAction.votedSide = "BLK"
        }
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        
        showToast(message: "Vote Submitted", length: 14)
        currentUserAction.changed = true
        
    }
    
    func commentHearted(commentID: String) {
        if let prevAction = currentUserAction.actionRecord[commentID] {
            switch prevAction {
            case "U":
                currentUserAction.actionRecord[commentID] = "N"
            case "D":
                currentUserAction.actionRecord[commentID] = "U"
            default:
                currentUserAction.actionRecord[commentID] = "U"
            }
        }
        else {
            //a new vote; send notification to author and increase their influence accordingly
            currentUserAction.actionRecord[commentID] = "U"
        }
        
        currentUserAction.changed = true
        
    }
    
    func commentBrokenhearted(commentID: String) {
        if let prevAction = currentUserAction.actionRecord[commentID] {
            switch prevAction {
            case "D":
                currentUserAction.actionRecord[commentID] = "N"
            case "U":
                currentUserAction.actionRecord[commentID] = "D"
            default:
                currentUserAction.actionRecord[commentID] = "D"
            }
        }
        else {
            //a new vote; send notification to author and increase their influence accordingly
            currentUserAction.actionRecord[commentID] = "D"
        }
        
        currentUserAction.changed = true
    }
    

}

protocol PostPageDelegator {
    func callSegueFromCell(profileUsername: String)
    func resizePostCardOnVote(red : Bool)
    func commentHearted(commentID : String)
    func commentBrokenhearted(commentID : String)
}
