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
    var parentVC : RootPageViewController?
    
    var vmrTap, profileTap : Bool!
    var vmrComment : VSComment!
    
    var fromIndex : Int?
    var nowLoading = false
    var loadThreshold = 8
    let retrievalSize = 16
    var reactivateLoadMore = false
    var fromIndexIncrement : Int?
    var topicComment : VSComment?
    
    var medalWinnersList = [String : String]() //commentID : medalType
    var winnerTreeRoots = NSMutableSet() //HashSet to prevent duplicate addition of medal winner's root into rootComments
    var medalistCQPayload = ""
    var medalistCQPayloadPostID = ""
    
    let goldPoints = 30
    let silverPoints = 15
    let bronzePoints = 5
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textInput.setNeedsLayout()
        commentSendButton.setNeedsLayout()
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
            if isMovingFromParentViewController && parentVC != nil {
                parentVC!.tableView.reloadData()
            }
            
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
    
    func commentClickSetUpChildPage (post : PostObject, comment : VSComment, userAction : UserAction, topicComment : VSComment) {
        parentVC = nil
        self.topicComment = topicComment
        comments.removeAll()
        updateMap.removeAll()
        nodeMap.removeAll()
        expandedCells.removeAllObjects()
        postVoteUpdate = "none"
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        currentPost = post
        fromIndex = 0
        nowLoading = false
        topCardComment = comment
        comments.append(topCardComment)
        self.rootComments.append(topicComment)
        self.nodeMap[topicComment.comment_id] = VSCNode(comment: topicComment)
        currentUserAction = userAction
        nodeMap[comment.comment_id] = VSCNode(comment: comment)
        medalistCQPayload = topicComment.comment_id
        medalistCQPayloadPostID = post.post_id
        setMedals() //this function will call commentsQuery() upon completion
        
        if let vcCount = navigationController?.viewControllers.count {
            if parentVC == nil {
                if vcCount > 1 {
                    parentVC = storyboard!.instantiateViewController(withIdentifier: "rootPage") as? RootPageViewController
                    let rView = parentVC?.view
                    navigationController?.viewControllers.insert(parentVC!, at: vcCount-1)
                    
                    parentVC?.setUpRootPage(post: currentPost, userAction: currentUserAction, fromCreatePost: false)
                    
                }
            }
            
        }
    }
    
    func setUpChildPage(post : PostObject, comment : VSComment, userAction : UserAction, parentPage : RootPageViewController?){
        parentVC = parentPage
        topicComment = nil
        comments.removeAll()
        updateMap.removeAll()
        nodeMap.removeAll()
        expandedCells.removeAllObjects()
        postVoteUpdate = "none"
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        currentPost = post
        fromIndex = 0
        nowLoading = false
        topCardComment = comment
        comments.append(topCardComment)
        currentUserAction = userAction
        nodeMap[comment.comment_id] = VSCNode(comment: comment)
        setMedals() //this function will call commentsQuery() upon completion
        
        if let vcCount = navigationController?.viewControllers.count {
            if parentVC == nil {
                if vcCount > 1 {
                    parentVC = storyboard!.instantiateViewController(withIdentifier: "rootPage") as? RootPageViewController
                    let rView = parentVC?.view
                    navigationController?.viewControllers.insert(parentVC!, at: vcCount-1)
                    
                    parentVC?.setUpRootPage(post: currentPost, userAction: currentUserAction, fromCreatePost: false)
                    
                }
            }
            
        }
    }
    
    func getNestedLevel(commentModel : VSCommentsListModel_hits_hits_item__source) -> Int {
        if commentModel.pr == topCardComment.comment_id {
            if commentModel.r != "0" {
                return 4
            }
            else {
                return 3
            }
        }
        
        return -1
    }
    
    func sendMedalNotification(newMedal : Int, item : VSCommentsListModel_hits_hits_item){
        var pointsIncrement = 0
        var usernameHash = getUsernameHash(username: item.source!.a!)
        var incrementKey : String!
        switch newMedal {
        case 3:
            incrementKey = "g"
            pointsIncrement = goldPoints
            
        case 2:
            incrementKey = "s"
            pointsIncrement = silverPoints
            
        case 1:
            incrementKey = "b"
            pointsIncrement = bronzePoints
            
        default:
            break
        }
        
        if incrementKey != nil {
            var decrementKey = ""
            switch item.source!.m {
            case 0:
                break
            case 1:
                decrementKey = "b"
                pointsIncrement -= bronzePoints
            case 2:
                decrementKey = "s"
                pointsIncrement -= silverPoints
            default:
                break
            }
            
            var medalType = incrementKey + decrementKey
            var timeValueSecs : Int = Int(NSDate().timeIntervalSince1970)
            var timeValue : Int = ((timeValueSecs / 60 ) / 60 ) / 24 ////now timeValue is in days since epoch
            
            let updateRequest = "updates/\(timeValue)/\(usernameHash)/\(item.source!.a!)/\(item.id!)/\(medalType)"
            var medalUpdateRequest = [String : Any]()
            medalUpdateRequest["c"] = sanitizeCommentContent(content: item.source!.ct!)
            medalUpdateRequest["p"] = pointsIncrement
            medalUpdateRequest["t"] = timeValueSecs
            ref.child(updateRequest).setValue(medalUpdateRequest)
            
            //medalWinner.setTopmedal(currentMedal) now we set the top medal outside this function, right after this function call returns
            
        }
        
        
    }
    
    func setMedals(){
        medalWinnersList.removeAll()
        winnerTreeRoots.removeAllObjects()
        apiClient.commentslistGet(c: nil, d: nil, a: "m", b: currentPost.post_id).continueWith(block:) {(task: AWSTask) -> AnyObject? in
            if task.error != nil {
                DispatchQueue.main.async {
                    print(task.error!)
                }
            }
            else {
                
                let group = DispatchGroup()
                
                
                if self.topicComment == nil {
                    self.medalistCQPayload = ""
                }
                self.medalistCQPayloadPostID = self.currentPost.post_id
                var mcq0, mcq1, mcq2 : String?
                var prevNode : VSCNode?
                
                if let results = task.result?.hits?.hits {
                    var i = 0
                    for item in results {
                        
                        switch i {
                        case 0: //gold
                            self.medalWinnersList[item.id!] = "g"
                            if item.source!.m!.intValue < 3 {
                                self.sendMedalNotification(newMedal: 3, item: item)
                            }
                            
                        case 1: //silver
                            self.medalWinnersList[item.id!] = "s"
                            if item.source!.m!.intValue < 2 {
                                self.sendMedalNotification(newMedal: 2, item: item)
                            }
                            
                        case 2: //bronze
                            self.medalWinnersList[item.id!] = "b"
                            if item.source!.m!.intValue < 1 {
                                self.sendMedalNotification(newMedal: 1, item: item)
                            }
                            
                            
                        default:
                            break
                            
                        }
                        
                        switch self.getNestedLevel(commentModel: item.source!) {
                        case 3:
                            let li = i
                            if !self.winnerTreeRoots.contains(item.id) {
                                self.winnerTreeRoots.add(item.id!)
                                let newComment = VSComment(itemSource: item.source!, id: item.id!)
                                newComment.nestedLevel = 3
                                self.rootComments.append(newComment)
                                self.nodeMap[newComment.comment_id] = VSCNode(comment: newComment)
                                
                                switch li {
                                case 0:
                                    mcq0 = newComment.comment_id
                                case 1:
                                    mcq1 = newComment.comment_id
                                case 2:
                                    mcq2 = newComment.comment_id
                                default:
                                    break
                                }
                            }
                        case 4:
                            let li = i
                            if !self.winnerTreeRoots.contains(item.source?.pr) {
                                self.winnerTreeRoots.add(item.source!.pr)
                                group.enter()
                                self.apiClient.commentGet(a: "c", b: item.source!.pr).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                                    
                                    if task.error != nil {
                                        DispatchQueue.main.async {
                                            print(task.error!)
                                        }
                                    }
                                    else {
                                        let getCommentResult = task.result
                                        
                                        let newComment = VSComment(itemSource: getCommentResult!.source!, id: getCommentResult!.id!)
                                        newComment.nestedLevel = 4
                                        self.rootComments.append(newComment)
                                        self.nodeMap[newComment.comment_id] = VSCNode(comment: newComment)
                                        
                                        switch li {
                                        case 0:
                                            mcq0 = newComment.comment_id
                                        case 1:
                                            mcq1 = newComment.comment_id
                                        case 2:
                                            mcq2 = newComment.comment_id
                                        default:
                                            break
                                        }
                                    }
                                    
                                    group.leave()
                                    
                                    return nil
                                }
                                
                            }
                            
                        default:
                            break
                        }
                        
                        i += 1
                    }
                }
                
                group.notify(queue: .main) {
                    if mcq0 != nil {
                        if self.topicComment != nil {
                            self.medalistCQPayload.append(","+mcq0!)
                        }
                        else {
                            self.medalistCQPayload.append(mcq0!)
                        }
                    }
                    if mcq1 != nil {
                        self.medalistCQPayload.append(","+mcq1!)
                    }
                    if mcq2 != nil {
                        self.medalistCQPayload.append(","+mcq2!)
                    }
                    self.commentsQuery(queryType: "rci")
                }
                
                
                
            }
            return nil
        }
        
    }
    
    func commentsQuery(queryType : String){
        if fromIndex == nil {
            fromIndex = 0
        }
        
        //get the root comments, children, and grandchildren
        apiClient.commentslistGet(c: topCardComment.comment_id, d: nil, a: queryType, b: "\(fromIndex!)").continueWith(block:) {(task: AWSTask) -> AnyObject? in
            print("child commentQuery with fromIndex == \(self.fromIndex!)")
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
                    
                    if self.medalistCQPayload.count > 0 && self.medalistCQPayloadPostID == self.currentPost.post_id {
                        cqPayload.append(self.medalistCQPayload+",")
                    }
                    
                    for item in rootQueryResults {
                        let comment = VSComment(itemSource: item.source!, id: item.id!)
                        comment.nestedLevel = 0
                        
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
                        
                        if !self.winnerTreeRoots.contains(comment.comment_id) {
                            print("sure come right thru commentID: " + comment.comment_id)
                            self.rootComments.append(comment)
                            
                            //build payload for child comment query
                            if cqPayloadIndex == 0 {
                                cqPayload.append(comment.comment_id)
                            }
                            else {
                                cqPayload.append(","+comment.comment_id)
                            }
                            
                            cqPayloadIndex += 1
                        }
                        
                        rootIndex += 1
                        
                    }
                    if self.topicComment != nil {
                        rootIndex += 1
                    }
                    
                    self.fromIndexIncrement = rootIndex
                    if rootIndex == self.retrievalSize {
                        self.reactivateLoadMore = true
                    }
                    else {
                        self.reactivateLoadMore = false
                        self.nowLoading = true
                    }
                    
                    if cqPayload.count > 9 && cqPayload[cqPayload.count-1] == "," {
                        cqPayload = String(cqPayload[0 ... cqPayload.count-2])
                    }
                    
                    if cqPayload.count > 0 {
                        
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
                                            childComment.nestedLevel = 4
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
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastElement = comments.count - 1 - loadThreshold
        if !nowLoading && indexPath.row == lastElement {
            nowLoading = true
            //fromIndex already set in commenteQuery, after getting root comments
            commentsQuery(queryType: "rci")
        }
    }
    
    
    
    func setComments(){
        
        for i in fromIndex!...rootComments.count-1{
            print("rootComments-\(i) = \(rootComments[i].content)")
            if let currentRootNode = nodeMap[rootComments[i].comment_id] {
                comments.append(currentRootNode.nodeContent)
                
                if let firstChild = currentRootNode.firstChild {
                    comments.append(firstChild.nodeContent)
                    
                    if let secondChild = firstChild.tailSibling {
                        comments.append(secondChild.nodeContent)
                    }
                }
            }
            
        }
        
        fromIndex! += fromIndexIncrement!
        DispatchQueue.main.async {
            self.tableView.reloadData()
            if self.reactivateLoadMore {
                self.nowLoading = false
            }
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
            
            if let medalType = medalWinnersList[comment.comment_id] {
                cell!.setCommentMedal(medalType: medalType)
            }
            
            cell!.delegate = self
            
            return cell!
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCard", for: indexPath) as? CommentCardTableViewCell
            let comment = comments[indexPath.row]
            
            let indent : CGFloat!
            print("nested level = \(comment.nestedLevel) for \(comment.content)")
            switch comment.nestedLevel {
            case 3:
                indent = 0
            case 4:
                indent = 1
            case 5:
                indent = 1
            default:
                indent = comment.nestedLevel
            }
            
            if let selection = currentUserAction.actionRecord[comment.comment_id] {
                switch selection {
                case "N":
                    cell!.setCell(comment: comment, indent: indent, row: indexPath.row)
                case "U":
                    cell!.setCellWithSelection(comment: comment, indent: indent, hearted: true, row: indexPath.row)
                case "D":
                    cell!.setCellWithSelection(comment: comment, indent: indent, hearted: false, row: indexPath.row)
                default:
                    cell!.setCell(comment: comment, indent: indent, row: indexPath.row)
                }
            }
            else {
                cell!.setCell(comment: comment, indent: indent, row: indexPath.row)
            }
            cell!.delegate = self
            
            return cell!
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if profileTap {
            guard let profileVC = segue.destination as? ProfileViewController else {return}
            profileVC.fromPostPage = true
            profileVC.currentUsername = tappedUsername!
        }
        else if vmrComment != nil{
            guard let grandchildPageVC = segue.destination as? GrandchildPageViewController else {return}
            let view = grandchildPageVC.view //to load the view
            //grandchildPageVC.fromRoot = false
            grandchildPageVC.setUpGrandchildPage(post: currentPost, comment: vmrComment!, userAction: currentUserAction, parentPage: self, grandparentPage: parentVC!)
        }
        
    }
    
    func callSegueFromCell(profileUsername: String) {
        profileTap = true
        vmrTap = false
        tappedUsername = profileUsername
        //try not to send self, just to avoid retain cycles(depends on how you handle the code on the next controller)
        performSegue(withIdentifier: "childToProfile", sender: self)
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
            
            if parentVC != nil {
                if let node = parentVC?.nodeMap[thisComment.comment_id] {
                    node.votedUpdate(upvotes: thisComment.upvotes, downvotes: thisComment.downvotes)
                }
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
            
            if parentVC != nil {
                if let node = parentVC?.nodeMap[thisComment.comment_id] {
                    node.votedUpdate(upvotes: thisComment.upvotes, downvotes: thisComment.downvotes)
                }
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
                
                if currentReplyTargetID != nil && currentReplyTargetID != topCardComment.comment_id {
                    
                    
                    if currentGrandchildRealTargetID != nil {
                        // an @reply at a grandchild comment. The actual parent of this comment will be the child comment.
                        
                        let newComment = VSComment(username: UserDefaults.standard.string(forKey: "KEY_USERNAME")!, parentID: currentReplyTargetID!, postID: currentPost.post_id, newContent: text, rootID: nodeMap[currentReplyTargetID!]!.nodeContent.parent_id)
                        
                        newComment.nestedLevel = 4
                        
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
                                if self.parentVC != nil {
                                    if let node = self.parentVC!.nodeMap[currentReplyTargetID!] {
                                        if let prevFirstChild = node.firstChild {
                                            node.firstChild = newCommentNode
                                            newCommentNode.tailSibling = prevFirstChild
                                            prevFirstChild.headSibling = newCommentNode
                                            prevFirstChild.parent = nil
                                            newCommentNode.parent = node
                                        }
                                        else {
                                            node.firstChild = newCommentNode
                                            newCommentNode.parent = node.firstChild
                                        }
                                        self.parentVC!.setCommentsFromChildPage()
                                    }
                                }
                                
                                self.sendCommentReplyNotification(replyTargetComment: self.nodeMap[currentGrandchildRealTargetID!]!.nodeContent)
                                
                            }
                            return nil
                        }
                        
                        
                    }
                    else { //a reply to a child comment
                        var rootID : String!
                        let replyTargetNode = nodeMap[currentReplyTargetID!]
                        let replyTarget = replyTargetNode!.nodeContent
                        let targetNestedLevel = replyTarget.nestedLevel
                        
                        let newComment = VSComment(username: UserDefaults.standard.string(forKey: "KEY_USERNAME")!, parentID: currentReplyTargetID!, postID: currentPost.post_id, newContent: text, rootID: replyTarget.parent_id)
                        
                        newComment.nestedLevel = 4
                        print("new comment nested at 4")
                        
                        apiClient.commentputPost(body: newComment.getPutModel(), c: newComment.comment_id, a: "put", b: "vscomment").continueWith(block:) {(task: AWSTask) -> AnyObject? in
                            if task.error != nil {
                                DispatchQueue.main.async {
                                    print(task.error!)
                                }
                            }
                            else {
                                
                                let newCommentNode = VSCNode(comment: newComment)
                                
                                
                                
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
                                if self.parentVC != nil {
                                    if let node = self.parentVC!.nodeMap[currentReplyTargetID!] {
                                        if let prevFirstChild = node.firstChild {
                                            node.firstChild = newCommentNode
                                            newCommentNode.tailSibling = prevFirstChild
                                            prevFirstChild.headSibling = newCommentNode
                                            prevFirstChild.parent = nil
                                            newCommentNode.parent = node
                                        }
                                        else {
                                            node.firstChild = newCommentNode
                                            newCommentNode.parent = node.firstChild
                                        }
                                        self.parentVC!.setCommentsFromChildPage()
                                    }
                                }
                                
                                self.sendCommentReplyNotification(replyTargetComment: replyTarget)
                                
                            }
                            return nil
                        }
                        
                    }
                    
                    
                }
                else {
                    // a reply to the top card
                    let newComment = VSComment(username: UserDefaults.standard.string(forKey: "KEY_USERNAME")!, parentID: topCardComment.comment_id, postID: topCardComment.post_id, newContent: text, rootID: "0")
                    newComment.nestedLevel = 3 //root comment in child page has nested level of 3 (which is 0 in root page)
                    print("new comment nested at 3")
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
                            if self.parentVC != nil {
                                if let node = self.parentVC!.nodeMap[self.topCardComment.comment_id] {
                                    if let prevFirstChild = node.firstChild {
                                        node.firstChild = newCommentNode
                                        newCommentNode.tailSibling = prevFirstChild
                                        prevFirstChild.headSibling = newCommentNode
                                        prevFirstChild.parent = nil
                                        newCommentNode.parent = node
                                    }
                                    else {
                                        node.firstChild = newCommentNode
                                        newCommentNode.parent = node.firstChild
                                    }
                                    self.parentVC!.setCommentsFromChildPage()
                                }
                            }
                            self.sendCommentReplyNotification(replyTargetComment: self.topCardComment)
                        }
                        return nil
                    }
                    
                }
                
                
            }
        }
    }
    
    
    func setCommentsFromChildPage() {
        comments.removeAll()
        comments.append(topCardComment)
        
        for i in 0...rootComments.count-1{
            let currentRootNode = nodeMap[rootComments[i].comment_id]
            comments.append(currentRootNode!.nodeContent)
            
            if let firstChild = currentRootNode?.firstChild {
                comments.append(firstChild.nodeContent)
                
                var childNode = firstChild
                while let tail = childNode.tailSibling {
                    comments.append(tail.nodeContent)
                    childNode = tail
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
    
    func sanitizeCommentContent(content : String) -> String {
        var strIn = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if strIn.count > 26 {
            strIn = String(strIn[..<26].trimmingCharacters(in: .whitespacesAndNewlines) + "...")
        }
        
        return strIn.replacingOccurrences(of: "[ /\\\\.\\\\$\\[\\]\\\\#]", with: "^", options: .regularExpression, range: nil).replacingOccurrences(of: ":", with: ";")
        
    }
    
    func sendCommentUpvoteNotification(upvotedComment : VSComment){
        
        if upvotedComment.author != "deleted" && upvotedComment.author != UserDefaults.standard.string(forKey: "KEY_USERNAME")! {
            let payloadContent = sanitizeCommentContent(content: upvotedComment.content)
            let commentAuthorPath = getUsernameHash(username: upvotedComment.author) + "/" + upvotedComment.author + "/n/u/" + upvotedComment.comment_id + ":" + payloadContent
            ref.child(commentAuthorPath).child(UserDefaults.standard.string(forKey: "KEY_USERNAME")!).setValue(Int(NSDate().timeIntervalSince1970))
        }
        
    }
    
    func sendCommentReplyNotification(replyTargetComment : VSComment){
        if replyTargetComment.author != "deleted" && replyTargetComment.author != UserDefaults.standard.string(forKey: "KEY_USERNAME")! {
            let payloadContent = sanitizeCommentContent(content: replyTargetComment.content)
            let commentAuthorPath = getUsernameHash(username: replyTargetComment.author) + "/" + replyTargetComment.author + "/n/c/" + replyTargetComment.comment_id + ":" + payloadContent
            ref.child(commentAuthorPath).child(UserDefaults.standard.string(forKey: "KEY_USERNAME")!).setValue(Int(NSDate().timeIntervalSince1970))
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
    
    func replyButtonTapped(replyTarget: VSComment, cell: CommentCardTableViewCell) {
        
        let row = tableView.indexPath(for: cell)!.row
        replyTargetRowNumber = row
        
        
        if replyTarget.nestedLevel != 1 {
            replyTargetID = replyTarget.comment_id
            grandchildRealTargetID = nil
            grandchildReplyTargetAuthor = nil
            
            textInput.text = ""
        }
        else if replyTarget.comment_id != topCardComment.comment_id{
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
        
        if replyTarget.comment_id != topCardComment.comment_id {
            tableView.cellForRow(at: IndexPath(row: row, section: 0))?.selectionStyle = UITableViewCellSelectionStyle.gray
        }
        
        tableView.selectRow(at: IndexPath(row: row, section: 0), animated: true, scrollPosition: UITableViewScrollPosition.top)
        
    }
    
    func viewMoreRepliesTapped(topCardComment: VSComment) {
        vmrTap = true
        profileTap = false
        vmrComment = topCardComment
        //go to grandchild page
        performSegue(withIdentifier: "childToGrandchild", sender: self)
        
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if grandchildRealTargetID != nil {
            return range.intersection(NSMakeRange(0, grandchildReplyTargetAuthor!.count+2)) == nil
        }
        return true
    }
    
}
