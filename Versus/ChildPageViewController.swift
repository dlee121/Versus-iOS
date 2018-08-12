//
//  RootPageViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 8/3/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import FirebaseDatabase


class ChildPageViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PostPageDelegator, UITextFieldDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textInput: UITextField!
    @IBOutlet weak var textInputContainer: UIView!
    @IBOutlet weak var textInputContainerBottom: NSLayoutConstraint!
    @IBOutlet weak var commentSendButton: UIButton!
    @IBOutlet weak var replyTargetLabel: UILabel!
    
    var currentPost : PostObject!
    var comments = [VSComment]()
    let apiClient = VSVersusAPIClient.default()
    var rootComments = [VSComment]()
    var childComments = [VSComment]()
    var grandchildComments = [VSComment]()
    var nodeMap = [String : VSCNode]()
    var currentUserAction : UserAction!
    var tappedUsername : String?
    var keyboardIsShowing = false
    var replyTargetID, grandchildRealTargetID, grandchildReplyTargetAuthor: String?
    var replyTargetRowNumber : Int?
    var ref: DatabaseReference!
    var expandedCells = NSMutableSet()
    var topCardComment : VSComment!
    
    /*
     updateMap = [commentID : action], action = u = upvote+influence, d = downvote, dci = downvote+influence,
     ud = upvote -> downvote, du = downvote -> upvote, un = upvote cancel, dn = downvote cancel
     */
    var updateMap = [String : String]()
    
    /*
     postVoteUpdate = r = red vote, b = black(blue) vote, rb = red to blue, br = blue to red
     
     */
    var postVoteUpdate : String!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //tableView.allowsSelection = false
        ref = Database.database().reference()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //hidesBottomBarWhenPushed = true
        super.viewWillAppear(animated)
        keyboardIsShowing = false
        self.tabBarController?.tabBar.isHidden = true
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillHide,
                                               object: nil)
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textInput.resignFirstResponder()
        
        if currentUserAction.changed {
            apiClient.recordPost(body: currentUserAction.getRecordPutModel(), a: "rcp", b: currentUserAction.id)
        }
        
        NotificationCenter.default.removeObserver(self)
        
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        keyboardIsShowing = true
        let userInfo: NSDictionary = notification.userInfo! as NSDictionary
        let keyboardInfo = userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue
        let keyboardSize = keyboardInfo.cgRectValue.size
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        tableView.contentInset = contentInsets
        tableView.scrollIndicatorInsets = contentInsets
        
        textInputContainerBottom.constant = -keyboardSize.height
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        keyboardIsShowing = false
        tableView.contentInset = .zero
        tableView.scrollIndicatorInsets = .zero
        textInputContainerBottom.constant = 0
        textInput.text = ""
        replyTargetID = nil
        grandchildRealTargetID = nil
        grandchildReplyTargetAuthor = nil
        replyTargetLabel.text = ""
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.cellForRow(at: indexPath)?.selectionStyle = UITableViewCellSelectionStyle.none
        }
        
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if keyboardIsShowing {
            textInputContainer.isHidden = true
            replyTargetLabel.isHidden = true
        }
        
    }
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        textInputContainer.isHidden = false
        replyTargetLabel.isHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUpChildPage(post : PostObject, comment : VSComment, userAction : UserAction){
        comments.removeAll()
        updateMap.removeAll()
        expandedCells.removeAllObjects()
        postVoteUpdate = "none"
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        currentPost = post
        topCardComment = comment
        comments.append(topCardComment)
        currentUserAction = userAction
        commentsQuery()
        nodeMap[comment.comment_id] = VSCNode(comment: comment)
        
    }
    
    func commentsQuery(){
        
        //get the root comments, children, and grandchildren
        apiClient.commentslistGet(c: topCardComment.comment_id, d: nil, a: "rci", b: "0").continueWith(block:) {(task: AWSTask) -> AnyObject? in
            
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
                                            
                                        }
                                        rIndex += 1
                                    }
                                    
                                    self.setComments()
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
                
                if let secondChild = firstChild.tailSibling {
                    comments.append(secondChild.nodeContent)
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
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 152
        }
        
        if expandedCells.contains(indexPath.row) {
            return 321
        }
        else {
            return 108
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TopCard", for: indexPath) as? CommentCardTableViewCell
            let comment = comments[indexPath.row]
            if let selection = currentUserAction.actionRecord[comment.comment_id] {
                switch selection {
                case "N":
                    cell!.setTopCardCell(comment: comment, row: indexPath.row, sortType: "Popular")
                case "U":
                    cell!.setTopCardCellWithSelection(comment: comment, hearted: true, row: indexPath.row, sortType: "Popular")
                case "D":
                    cell!.setTopCardCellWithSelection(comment: comment, hearted: false, row: indexPath.row, sortType: "Popular")
                default:
                    cell!.setTopCardCell(comment: comment, row: indexPath.row, sortType: "Popular")
                }
            }
            else {
                cell!.setTopCardCell(comment: comment, row: indexPath.row, sortType: "Popular")
            }
            cell!.delegate = self
            
            return cell!
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCard", for: indexPath) as? CommentCardTableViewCell
            let comment = comments[indexPath.row]
            if let selection = currentUserAction.actionRecord[comment.comment_id] {
                switch selection {
                case "N":
                    cell!.setCell(comment: comment, indent: comment.nestedLevel!, row: indexPath.row)
                case "U":
                    cell!.setCellWithSelection(comment: comment, indent: comment.nestedLevel!, hearted: true, row: indexPath.row)
                case "D":
                    cell!.setCellWithSelection(comment: comment, indent: comment.nestedLevel!, hearted: false, row: indexPath.row)
                default:
                    cell!.setCell(comment: comment, indent: comment.nestedLevel!, row: indexPath.row)
                }
            }
            else {
                cell!.setCell(comment: comment, indent: comment.nestedLevel!, row: indexPath.row)
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
        //empty method to conform to PostPageDelegator protocol
        
    }
    
    func commentHearted(commentID: String) {
        print("votedCommentID: \(commentID)")
        if let thisComment = nodeMap[commentID]?.nodeContent {
            if let prevAction = currentUserAction.actionRecord[commentID] {
                switch prevAction {
                case "U":
                    apiClient.vGet(e: nil, c: commentID, d: nil, a: "v", b: "un")
                    currentUserAction.actionRecord[commentID] = "N"
                    thisComment.upvotes -= 1
                case "D":
                    apiClient.vGet(e: nil, c: commentID, d: nil, a: "v", b: "du")
                    currentUserAction.actionRecord[commentID] = "U"
                    thisComment.downvotes -= 1
                    thisComment.upvotes += 1
                default:
                    apiClient.vGet(e: nil, c: commentID, d: nil, a: "v", b: "u")
                    currentUserAction.actionRecord[commentID] = "U"
                    thisComment.upvotes += 1
                }
            }
            else {
                //a new vote; send notification to author and increase their influence accordingly
                sendCommentUpvoteNotification(upvotedComment: nodeMap[commentID]!.nodeContent)
                
                apiClient.vGet(e: nil, c: commentID, d: nil, a: "v", b: "u")
                apiClient.vGet(e: nil, c: thisComment.author, d: nil, a: "ui", b: "1")
                currentUserAction.actionRecord[commentID] = "U"
                thisComment.upvotes += 1
            }
        }
        
        currentUserAction.changed = true
    }
    
    func commentBrokenhearted(commentID: String) {
        if let thisComment = nodeMap[commentID]?.nodeContent {
            if let prevAction = currentUserAction.actionRecord[commentID] {
                switch prevAction {
                case "D":
                    apiClient.vGet(e: nil, c: commentID, d: nil, a: "v", b: "dn")
                    currentUserAction.actionRecord[commentID] = "N"
                    thisComment.downvotes -= 1
                case "U":
                    apiClient.vGet(e: nil, c: commentID, d: nil, a: "v", b: "ud")
                    currentUserAction.actionRecord[commentID] = "D"
                    thisComment.upvotes -= 1
                    thisComment.downvotes += 1
                default:
                    if (thisComment.upvotes == 0 && thisComment.downvotes + 1 <= 10) || (thisComment.upvotes * 10 >= thisComment.downvotes + 1) {
                        apiClient.vGet(e: nil, c: commentID, d: nil, a: "v", b: "dci")
                    }
                    else {
                        apiClient.vGet(e: nil, c: commentID, d: nil, a: "v", b: "d")
                    }
                    currentUserAction.actionRecord[commentID] = "D"
                    thisComment.downvotes += 1
                }
            }
            else {
                //a new vote; send notification to author and increase their influence accordingly
                sendCommentUpvoteNotification(upvotedComment: nodeMap[commentID]!.nodeContent)
                
                if (thisComment.upvotes == 0 && thisComment.downvotes + 1 <= 10) || (thisComment.upvotes * 10 >= thisComment.downvotes + 1) {
                    apiClient.vGet(e: nil, c: commentID, d: nil, a: "v", b: "dci")
                }
                else {
                    apiClient.vGet(e: nil, c: commentID, d: nil, a: "v", b: "d")
                }
                currentUserAction.actionRecord[commentID] = "D"
                thisComment.downvotes += 1
            }
        }
        
        currentUserAction.changed = true
    }
    
    @IBAction func textChangeListener(_ sender: UITextField) {
        if let input = textInput.text{
            if input.count > 0 {
                commentSendButton.isEnabled = true
                commentSendButton.setBackgroundImage(#imageLiteral(resourceName: "ic_send_blue"), for: .normal)
            }
            else {
                commentSendButton.isEnabled = false
                commentSendButton.setBackgroundImage(#imageLiteral(resourceName: "ic_send_grey"), for: .normal)
            }
        }
        else {
            commentSendButton.isEnabled = false
            commentSendButton.setBackgroundImage(#imageLiteral(resourceName: "ic_send_grey"), for: .normal)
        }
    }
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        let currentReplyTargetID = replyTargetID
        let currentGrandchildRealTargetID = grandchildRealTargetID
        
        if let text = textInput.text {
            if text.count > 0 {
                
                textInput.text = ""
                textInput.resignFirstResponder()
                
                if currentReplyTargetID != nil {
                    if currentGrandchildRealTargetID != nil {
                        // an @reply at a grandchild comment. The actual parent of this comment will be the child comment.
                        
                        let newComment = VSComment(username: UserDefaults.standard.string(forKey: "KEY_USERNAME")!, parentID: currentReplyTargetID!, postID: currentPost.post_id, newContent: text, rootID: nodeMap[currentReplyTargetID!]!.nodeContent.parent_id)
                        
                        newComment.nestedLevel = 2
                        
                        apiClient.commentputPost(body: newComment.getPutModel(), c: newComment.comment_id, a: "put", b: "vscomment").continueWith(block:) {(task: AWSTask) -> AnyObject? in
                            if task.error != nil {
                                DispatchQueue.main.async {
                                    print(task.error!)
                                }
                            }
                            else {
                                
                                let newCommentNode = VSCNode(comment: newComment)
                                
                                if let grandchildReplyTargetNode = self.nodeMap[currentGrandchildRealTargetID!] {
                                    if let prevTailNode = grandchildReplyTargetNode.tailSibling {
                                        prevTailNode.headSibling = newCommentNode
                                        newCommentNode.tailSibling = prevTailNode
                                    }
                                    grandchildReplyTargetNode.tailSibling = newCommentNode
                                    newCommentNode.headSibling = grandchildReplyTargetNode
                                }
                                
                                self.nodeMap[newComment.comment_id] = newCommentNode
                                
                                if self.replyTargetRowNumber! + 1 >= self.comments.count {
                                    self.comments.append(newComment)
                                }
                                else {
                                    self.comments.insert(newComment, at: self.replyTargetRowNumber! + 1)
                                }
                                
                                print("newCommentID: \(newComment.comment_id)")
                                
                                DispatchQueue.main.async {
                                    self.tableView.insertRows(at: [IndexPath(row: self.replyTargetRowNumber! + 1, section: 0)], with: .fade)
                                }
                                
                                self.apiClient.vGet(e: nil, c: self.currentPost.post_id, d: nil, a: "v", b: "cm") //ps increment for comment submission
                                
                            }
                            return nil
                        }
                        
                        
                    }
                    else { //a reply to a root comment or a child comment
                        var rootID : String!
                        let replyTarget = nodeMap[currentReplyTargetID!]!.nodeContent
                        let targetNestedLevel = replyTarget.nestedLevel
                        if targetNestedLevel == 0 { //reply to a root comment
                            print("root reply tap")
                            rootID = "0"
                        }
                        else { //reply to a child comment
                            print("child reply tap")
                            rootID = replyTarget.parent_id
                        }
                        
                        let newComment = VSComment(username: UserDefaults.standard.string(forKey: "KEY_USERNAME")!, parentID: currentReplyTargetID!, postID: currentPost.post_id, newContent: text, rootID: rootID)
                        
                        newComment.nestedLevel = targetNestedLevel! + 1 //root comment in root page has nested level of 0
                        
                        
                        apiClient.commentputPost(body: newComment.getPutModel(), c: newComment.comment_id, a: "put", b: "vscomment").continueWith(block:) {(task: AWSTask) -> AnyObject? in
                            if task.error != nil {
                                DispatchQueue.main.async {
                                    print(task.error!)
                                }
                            }
                            else {
                                
                                let newCommentNode = VSCNode(comment: newComment)
                                
                                let replyTargetNode = self.nodeMap[currentReplyTargetID!]
                                
                                if let prevTopChildNode = replyTargetNode!.firstChild {
                                    replyTargetNode!.firstChild = newCommentNode
                                    newCommentNode.tailSibling = prevTopChildNode
                                    prevTopChildNode.headSibling = newCommentNode
                                }
                                else {
                                    replyTargetNode!.firstChild = newCommentNode
                                }
                                self.nodeMap[newComment.comment_id] = newCommentNode
                                
                                if self.replyTargetRowNumber! + 1 >= self.comments.count {
                                    self.comments.append(newComment)
                                }
                                else {
                                    self.comments.insert(newComment, at: self.replyTargetRowNumber! + 1)
                                }
                                
                                print("newCommentID: \(newComment.comment_id)")
                                
                                DispatchQueue.main.async {
                                    self.tableView.insertRows(at: [IndexPath(row: self.replyTargetRowNumber! + 1, section: 0)], with: .fade)
                                }
                                
                                self.apiClient.vGet(e: nil, c: self.currentPost.post_id, d: nil, a: "v", b: "cm") //ps increment for comment submission
                                
                            }
                            return nil
                        }
                        
                    }
                }
                else {
                    // a root comment to the post
                    let newComment = VSComment(username: UserDefaults.standard.string(forKey: "KEY_USERNAME")!, parentID: currentPost.post_id, postID: currentPost.post_id, newContent: text, rootID: "0")
                    newComment.nestedLevel = 0 //root comment in root page has nested level of 0
                    
                    apiClient.commentputPost(body: newComment.getPutModel(), c: newComment.comment_id, a: "put", b: "vscomment").continueWith(block:) {(task: AWSTask) -> AnyObject? in
                        if task.error != nil {
                            DispatchQueue.main.async {
                                print(task.error!)
                            }
                        }
                        else {
                            
                            let newCommentNode = VSCNode(comment: newComment)
                            if self.comments.count > 1 { //at least one another root comment in the page
                                let prevTopCommentNode = self.nodeMap[self.comments[1].comment_id]
                                
                                newCommentNode.tailSibling = prevTopCommentNode
                                prevTopCommentNode?.headSibling = newCommentNode
                            }
                            
                            self.nodeMap[newComment.comment_id] = newCommentNode
                            
                            print("newCommentID: \(newComment.comment_id)")
                            
                            DispatchQueue.main.async {
                                self.rootComments.insert(newComment, at: 0)
                                self.comments.insert(newComment, at: 1)
                                self.tableView.insertRows(at: [IndexPath(row: 1, section: 0)], with: .fade)
                            }
                            
                            self.apiClient.vGet(e: nil, c: self.currentPost.post_id, d: nil, a: "v", b: "cm") //ps increment for comment submission
                            
                        }
                        return nil
                    }
                    
                }
            }
        }
    }
    
    func beginUpdatesForSeeMore(row : Int) {
        expandedCells.add(row)
        tableView.beginUpdates()
    }
    
    func beginUpdates() {
        tableView.beginUpdates()
    }
    
    func endUpdates() {
        tableView.endUpdates()
    }
    
    func endUpdatesForSeeLess(row: Int) {
        tableView.endUpdates()
        expandedCells.remove(row)
    }
    
    func sanitizeContentForURL(content : String) -> String{
        
        var strIn = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if strIn.count > 26 {
            strIn = String(strIn[..<26]) //test this
        }
        
        return strIn.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "[ /\\\\.\\\\$\\[\\]\\\\#]", with: "^", options: .regularExpression, range: nil).replacingOccurrences(of: ":", with: ";")
    }
    
    func sendCommentUpvoteNotification(upvotedComment : VSComment){
        
        if upvotedComment.author != "deleted" && upvotedComment.author != UserDefaults.standard.string(forKey: "KEY_USERNAME")! {
            let payloadContent = sanitizeContentForURL(content: upvotedComment.content)
            let commentAuthorPath = getUsernameHash(username: upvotedComment.author) + "/" + upvotedComment.author + "/n/u/" + upvotedComment.comment_id + ":" + payloadContent
            ref.child(commentAuthorPath).child(UserDefaults.standard.string(forKey: "KEY_USERNAME")!).setValue(Int(NSDate().timeIntervalSince1970))
        }
        
    }
    
    func sendPostVoteNotification() {
        
        if currentPost.author != "deleted" && currentPost.author != UserDefaults.standard.string(forKey: "KEY_USERNAME")! {
            let nKey = currentPost.post_id + ":" + sanitizeContentForURL(content: currentPost.redname)+":"+sanitizeContentForURL(content: currentPost.blackname)+":"+sanitizeContentForURL(content: currentPost.question)
            let postAuthorPath = getUsernameHash(username: currentPost.author) + "/" + currentPost.author + "/n/v/" + nKey
            ref.child(postAuthorPath).child(UserDefaults.standard.string(forKey: "KEY_USERNAME")!).setValue(Int(NSDate().timeIntervalSince1970))
        }
        
    }
    
    func getUsernameHash(username : String) -> String {
        var usernameHash : Int32
        if(username.count < 5){
            usernameHash = username.hashCode()
        }
        else{
            var hashIn = ""
            
            hashIn.append(username[0])
            hashIn.append(username[username.count-2])
            hashIn.append(username[1])
            hashIn.append(username[username.count-1])
            
            usernameHash = hashIn.hashCode()
        }
        
        return "\(usernameHash)"
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if replyTargetID != nil {
            return tableView.indexPathForSelectedRow
        }
        return indexPath
    }
    
    func replyButtonTapped(replyTarget: VSComment, row: Int) {
        
        replyTargetRowNumber = row
        
        if replyTarget.nestedLevel != 2 {
            replyTargetID = replyTarget.comment_id
            grandchildRealTargetID = nil
            grandchildReplyTargetAuthor = nil
            
            textInput.text = ""
        }
        else {
            grandchildReplyTargetAuthor = replyTarget.author
            grandchildRealTargetID = replyTarget.comment_id
            replyTargetID = replyTarget.parent_id
            
            textInput.text = "@"+grandchildReplyTargetAuthor! + " "
        }
        
        textInput.becomeFirstResponder()
        replyTargetLabel.text = "Replying to: \(replyTarget.author)"
        
        if let indexPath = tableView.indexPathForSelectedRow {
            if indexPath.row != row {
                tableView.cellForRow(at: indexPath)?.selectionStyle = UITableViewCellSelectionStyle.none
            }
        }
        
        tableView.cellForRow(at: IndexPath(row: row, section: 0))?.selectionStyle = UITableViewCellSelectionStyle.gray
        tableView.selectRow(at: IndexPath(row: row, section: 0), animated: true, scrollPosition: UITableViewScrollPosition.top)
        //tableView.scrollToRow(at: IndexPath(row: row, section: 0), at: UITableViewScrollPosition.top, animated: true)
        
    }
    
    func viewMoreRepliesTapped(topCardComment: VSComment) {
        //go to grandchild page
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if grandchildRealTargetID != nil {
            return range.intersection(NSMakeRange(0, grandchildReplyTargetAuthor!.count+2)) == nil
        }
        return true
    }
    
}
