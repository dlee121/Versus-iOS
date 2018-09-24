//
//  RootPageViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 8/3/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import FirebaseDatabase


class RootPageViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PostPageDelegator, UITextFieldDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textInput: UITextField!
    @IBOutlet weak var textInputContainer: UIView!
    @IBOutlet weak var textInputContainerBottom: NSLayoutConstraint!
    
    @IBOutlet weak var commentSendButton: UIButton!
    @IBOutlet weak var replyTargetLabel: UILabel!
    
    
    var currentPost : PostObject!
    var comments = [VSComment]()
    
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
    
    var profileTap, vmrTap : Bool!
    var vmrComment : VSComment?
    
    var fromCreatePost : Bool!
    var createPostVC : CreatePostViewController?
    
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
    
    var sortType = 0
    let POPULAR = 0
    let MOST_RECENT = 1
    let CHRONOLOGICAL = 2
    var sortTypeString = "Popular"
    
    var editSegue = false
    var commentsLoaded = false
    
    
    /*
        updateMap = [commentID : action], action = u = upvote+influence, d = downvote, dci = downvote+influence,
            ud = upvote -> downvote, du = downvote -> upvote, un = upvote cancel, dn = downvote cancel
    */
    var updateMap = [String : String]()
    
    /*
        postVoteUpdate = r = red vote, b = black(blue) vote, rb = red to blue, br = blue to red
 
    */
    var postVoteUpdate : String!
    
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "overflowVertical"), style: .done, target: self, action: #selector(postPageOverflowMenuTapped))
        
        tableView.separatorStyle = .none
        
        //tableView.allowsSelection = false
        ref = Database.database().reference()
        
        // Add Refresh Control to Table View
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        
        // Configure Refresh Control
        refreshControl.addTarget(self, action: #selector(refreshList(_:)), for: .valueChanged)
    }
    
    @objc
    func postPageOverflowMenuTapped() {
        print("overflow my friends")
        if currentPost != nil {
            if currentPost.author == UserDefaults.standard.string(forKey: "KEY_USERNAME") {
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                
                alert.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
                
                alert.addAction(UIAlertAction(title: "Edit", style: .default, handler: { _ in
                    self.editSegue = true
                    self.performSegue(withIdentifier: "rootToEditPost", sender: self)
                }))
                
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                    if self.commentsLoaded {
                        if self.comments.count == 1 { //only contains post card placeholder
                            VSVersusAPIClient.default().deleteGet(a: "del", b: self.currentPost.post_id).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                                if task.error != nil {
                                    DispatchQueue.main.async {
                                        print(task.error!)
                                    }
                                }
                                else {
                                    
                                    DispatchQueue.main.async {
                                        if let navigationStack = self.navigationController?.childViewControllers {
                                            let parentVC = navigationStack[navigationStack.count-2]
                                            if let meORnew = self.currentPost.meORnew {
                                                switch meORnew {
                                                case 0: //from MeVC
                                                    (parentVC as! MeViewController).handlePostDelete(postID: self.currentPost.post_id, index: self.currentPost.meORnewIndex!)
                                                case 1: //from Tab3NewVC
                                                    (parentVC as! MCViewController).handlePostDelete(postID: self.currentPost.post_id, index: self.currentPost.meORnewIndex!)
                                                default:
                                                    break
                                                }
                                            }
                                        }
                                        self.navigationController!.popViewController(animated: true)
                                    }
                                    
                                }
                                return nil
                            }
                            
                        }
                        else { //post has comments so don't delete the post, just set the author to "deleted"
                            
                            VSVersusAPIClient.default().deleteGet(a: "ppd", b: self.currentPost.post_id).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                                if task.error != nil {
                                    DispatchQueue.main.async {
                                        print(task.error!)
                                    }
                                }
                                else {
                                    
                                    DispatchQueue.main.async {
                                        if let navigationStack = self.navigationController?.childViewControllers {
                                            let parentVC = navigationStack[navigationStack.count-2]
                                            if let meORnew = self.currentPost.meORnew {
                                                switch meORnew {
                                                case 0: //from MeVC
                                                    (parentVC as! MeViewController).handlePostDelete(postID: self.currentPost.post_id, index: self.currentPost.meORnewIndex!)
                                                case 1: //from Tab3NewVC
                                                    (parentVC as! MCViewController).handlePostDelete(postID: self.currentPost.post_id, index: self.currentPost.meORnewIndex!)
                                                default:
                                                    break
                                                }
                                            }
                                        }
                                        self.navigationController!.popViewController(animated: true)
                                    }
                                    
                                }
                                return nil
                            }
                            
                        }
                        
                        
                    }
                    
                }))
                
                alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
                
            }
            else {
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                
                alert.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
                
                alert.addAction(UIAlertAction(title: "Report", style: .default, handler: { _ in
                    //self.openGallary()
                }))
                
                alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
            }
        }
        
    }
    
    @objc private func refreshList(_ sender: Any) {
        if comments.count > 1 && currentPost != nil && currentUserAction != nil {
            rootComments.removeAll()
            childComments.removeAll()
            grandchildComments.removeAll()
            comments.removeAll()
            tableView.reloadData()
            
            self.setUpRootPage(post: currentPost, userAction: self.currentUserAction, fromCreatePost: false)
        }
        else {
            refreshControl.endRefreshing()
        }
    }
    
    func sortRefresh(_ sender: Any){
        fromIndex = 0
        
        rootComments.removeAll()
        childComments.removeAll()
        grandchildComments.removeAll()
        comments.removeAll()
        
        
        winnerTreeRoots.removeAllObjects()
        medalistCQPayload = ""
        
        topicComment = nil
        expandedCells.removeAllObjects()
        nowLoading = false
        
        comments.append(VSComment()) //placeholder for post object
        tableView.reloadData()
        
        
        if sortType == POPULAR {
            setMedals()
        }
        else {
            commentsQuery()
        }
        
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
        editSegue = false
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
        editSegue = false
        if currentUserAction.changed {
            VSVersusAPIClient.default().recordPost(body: currentUserAction.getRecordPutModel(), a: "rcp", b: currentUserAction.id)
        }
        
        if isMovingFromParentViewController && fromCreatePost && createPostVC != nil{
            createPostVC?.backButtonTapped()
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
        //textInput.text = ""
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
    
    func commentClickSetUpRootPage (post : PostObject, userAction : UserAction, topicComment : VSComment) {
        sortType = POPULAR
        sortTypeString = "Popular"
        fromCreatePost = false
        self.topicComment = topicComment
        comments.removeAll()
        rootComments.removeAll()
        updateMap.removeAll()
        nodeMap.removeAll()
        expandedCells.removeAllObjects()
        postVoteUpdate = "none"
        
        currentPost = post
        fromIndex = 0
        nowLoading = false
        comments.append(VSComment()) //placeholder for post object
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
        
        self.rootComments.append(topicComment)
        self.nodeMap[topicComment.comment_id] = VSCNode(comment: topicComment)
        currentUserAction = userAction
        medalistCQPayload = topicComment.comment_id
        medalistCQPayloadPostID = post.post_id
        setMedals() //this function will call commentsQuery() upon completion
    }
    
    func setUpRootPage(post : PostObject, userAction : UserAction, fromCreatePost : Bool){
        sortType = POPULAR
        sortTypeString = "Popular"
        self.fromCreatePost = fromCreatePost
        topicComment = nil
        comments.removeAll()
        rootComments.removeAll()
        updateMap.removeAll()
        nodeMap.removeAll()
        expandedCells.removeAllObjects()
        postVoteUpdate = "none"
        
        currentPost = post
        fromIndex = 0
        nowLoading = false
        comments.append(VSComment()) //placeholder for post object
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
        currentUserAction = userAction
        setMedals() //this function will call commentsQuery() upon completion
        
    }
    
    func getNestedLevel(commentModel : VSCommentsListModel_hits_hits_item__source) -> Int {
        if commentModel.pr == commentModel.pt {
            return 0
        }
        else if commentModel.r == "0" {
            return 1
        }
        else {
            return 2
        }
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
            
            print("medal update triggered")
            
            //medalWinner.setTopmedal(currentMedal) now we set the top medal outside this function, right after this function call returns
            
        }
        
        
    }
    
    func setMedals(){
        if comments.count == 1 {
            commentsLoaded = false
        }
        
        medalWinnersList.removeAll()
        winnerTreeRoots.removeAllObjects()
        VSVersusAPIClient.default().commentslistGet(c: nil, d: nil, a: "m", b: currentPost.post_id).continueWith(block:) {(task: AWSTask) -> AnyObject? in
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
                var r0, r1, r2 : VSComment?
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
                        case 0:
                            let li = i
                            if !self.winnerTreeRoots.contains(item.id) {
                                self.winnerTreeRoots.add(item.id!)
                                let newComment = VSComment(itemSource: item.source!, id: item.id!)
                                newComment.nestedLevel = 0
                                
                                if self.topicComment == nil || self.topicComment?.comment_id != item.id! {
                                    
                                    self.nodeMap[newComment.comment_id] = VSCNode(comment: newComment)
                                    switch li {
                                    case 0:
                                        mcq0 = newComment.comment_id
                                        r0 = newComment
                                    case 1:
                                        mcq1 = newComment.comment_id
                                        r1 = newComment
                                    case 2:
                                        mcq2 = newComment.comment_id
                                        r2 = newComment
                                    default:
                                        break
                                    }
                                }
                                
                                
                            }
                        case 1:
                            let li = i
                            if !self.winnerTreeRoots.contains(item.source?.pr) {
                                self.winnerTreeRoots.add(item.source!.pr)
                                group.enter()
                                VSVersusAPIClient.default().commentGet(a: "c", b: item.source!.pr).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                                    
                                    if task.error != nil {
                                        DispatchQueue.main.async {
                                            print(task.error!)
                                        }
                                    }
                                    else {
                                        let getCommentResult = task.result
                                        
                                        let newComment = VSComment(itemSource: getCommentResult!.source!, id: getCommentResult!.id!)
                                        newComment.nestedLevel = 0
                                        if self.topicComment == nil || self.topicComment?.comment_id != item.id! {
                                            
                                            self.nodeMap[newComment.comment_id] = VSCNode(comment: newComment)
                                            switch li {
                                            case 0:
                                                mcq0 = newComment.comment_id
                                                r0 = newComment
                                            case 1:
                                                mcq1 = newComment.comment_id
                                                r1 = newComment
                                            case 2:
                                                mcq2 = newComment.comment_id
                                                r2 = newComment
                                            default:
                                                break
                                            }
                                        }
                                        
                                        
                                    }
                                    
                                    group.leave()
                                    
                                    return nil
                                }
                                
                            }
                            
                        case 2:
                            let li = i
                            if !self.winnerTreeRoots.contains(item.source?.r) {
                                self.winnerTreeRoots.add(item.source!.r)
                                group.enter()
                                VSVersusAPIClient.default().commentGet(a: "c", b: item.source?.r).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                                    
                                    if task.error != nil {
                                        DispatchQueue.main.async {
                                            print(task.error!)
                                        }
                                    }
                                    else {
                                        let getCommentResult = task.result
                                        
                                        let newComment = VSComment(itemSource: getCommentResult!.source!, id: getCommentResult!.id!)
                                        newComment.nestedLevel = 0
                                        if self.topicComment == nil || self.topicComment?.comment_id != item.id! {
                                            
                                            self.nodeMap[newComment.comment_id] = VSCNode(comment: newComment)
                                            switch li {
                                            case 0:
                                                mcq0 = newComment.comment_id
                                                r0 = newComment
                                            case 1:
                                                mcq1 = newComment.comment_id
                                                r1 = newComment
                                            case 2:
                                                mcq2 = newComment.comment_id
                                                r2 = newComment
                                            default:
                                                break
                                            }
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
                        self.rootComments.append(r0!)
                    }
                    if mcq1 != nil {
                        self.medalistCQPayload.append(","+mcq1!)
                        self.rootComments.append(r1!)
                    }
                    if mcq2 != nil {
                        self.medalistCQPayload.append(","+mcq2!)
                        self.rootComments.append(r2!)
                    }
                    
                    //print("mcq: "+self.medalistCQPayload)
                    
                    self.commentsQuery()
                }
                
                
                
            }
            
            
            
            return nil
        }
        
    }
    
    func commentsQuery(){
        if comments.count == 1 {
            commentsLoaded = false
        }
        
        startIndicator()
        
        if fromIndex == nil {
            fromIndex = 0
        }
        
        var queryType, ascORdesc : String!
        
        switch sortType {
        case POPULAR:
            queryType = "rci"
            ascORdesc = nil
        case MOST_RECENT:
            queryType = "rct"
            ascORdesc = "desc"
        case CHRONOLOGICAL:
            queryType = "rct"
            ascORdesc = "asc"
        default:
            queryType = "rci"
            ascORdesc = nil
        }
        
        //get the root comments, children, and grandchildren
        VSVersusAPIClient.default().commentslistGet(c: currentPost.post_id, d: ascORdesc, a: queryType, b: "\(fromIndex!)").continueWith(block:) {(task: AWSTask) -> AnyObject? in
            print("commentQuery with fromIndex == \(self.fromIndex!)")
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
                        
                        if !(self.winnerTreeRoots.contains(comment.comment_id) || (self.topicComment != nil && self.topicComment!.comment_id == comment.comment_id)) {
                            
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
                    
                    if rootQueryResults.count == 0 {
                        DispatchQueue.main.async {
                            self.refreshControl.endRefreshing()
                            self.commentsLoaded = true
                        }
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
                        print("cqpayload was \(cqPayload)")
                        //child comments query
                        VSVersusAPIClient.default().cgcGet(a: "cgc", b: cqPayload).continueWith(block:) {(cqTask: AWSTask) -> AnyObject? in
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
                                        let rootNode = self.nodeMap[currentRoot.comment_id]
                                        rootNode!.nodeContent.child_count = cqHitsObject!.total!.intValue //set child count for parent root comment
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
                                        VSVersusAPIClient.default().cgcGet(a: "cgc", b: gcqPayload).continueWith(block:) {(gcqTask: AWSTask) -> AnyObject? in
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
                                                        let parentNode = self.nodeMap[currentParent.comment_id]
                                                        parentNode!.nodeContent.child_count = gcqHitsObject?.total!.intValue //set child count for parent root comment
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
                            self.commentsLoaded = true
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
            commentsQuery()
        }
    }
    
    
    
    func setComments(){
        
        for i in fromIndex!...rootComments.count-1{
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
                    
                    if let firstGrandchild = secondChild.firstChild {
                        comments.append(firstGrandchild.nodeContent)
                        
                        if let secondGrandchild = firstGrandchild.tailSibling {
                            comments.append(secondGrandchild.nodeContent)
                        }
                    }
                }
            }
            
        }
        fromIndex! += fromIndexIncrement!
        DispatchQueue.main.async {
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
            
            self.tableView.reloadData()
            
            if self.reactivateLoadMore {
                self.nowLoading = false
            }
        }
        commentsLoaded = true
    }
    
    func setCommentsFromChildPage() {
        comments.removeAll()
        comments.append(VSComment())
        
        for i in 0...rootComments.count-1{
            let currentRootNode = nodeMap[rootComments[i].comment_id]
            comments.append(currentRootNode!.nodeContent)
            
            if let firstChild = currentRootNode?.firstChild {
                comments.append(firstChild.nodeContent)
                
                if let firstGrandchild = firstChild.firstChild {
                    comments.append(firstGrandchild.nodeContent)
                    
                    var grandchildNode = firstGrandchild
                    while let grandTail = grandchildNode.tailSibling {
                        comments.append(grandTail.nodeContent)
                        grandchildNode = grandTail
                    }
                }
                
                
                var childNode = firstChild
                while let tail = childNode.tailSibling {
                    comments.append(tail.nodeContent)
                    
                    if let firstGrandchild = tail.firstChild {
                        comments.append(firstGrandchild.nodeContent)
                        
                        var grandchildNode = firstGrandchild
                        while let grandTail = grandchildNode.tailSibling {
                            comments.append(grandTail.nodeContent)
                            grandchildNode = grandTail
                        }
                    }
                    
                    childNode = tail
                }
            }
            
        }
        
        print("new comments size: \(comments.count)")
        
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 372
        }
        else if expandedCells.contains(indexPath.row) {
            return 303
        }
        else {
            return 90
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 { //for RootPage, first item of the comments list is a placeholder for the post object
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostCard", for: indexPath) as? PostCardTableViewCell
            cell!.setCell(post: currentPost, votedSide: currentUserAction.votedSide, sortType: sortTypeString)
            cell!.delegate = self
            return cell!
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCard", for: indexPath) as? CommentCardTableViewCell
            let comment = comments[indexPath.row]
            let indent : CGFloat!
            switch comment.nestedLevel {
            case 0:
                indent = 0
            case 1:
                indent = 1
            case 2:
                indent = 2
            case 3:
                indent = 1
            case 4:
                indent = 2
            case 5:
                indent = 2
            default:
                indent = 0
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
            
            if let medalType = medalWinnersList[comment.comment_id] {
                cell!.setCommentMedal(medalType: medalType)
            }
            else {
                cell!.removeMedalView()
            }
            
            cell!.delegate = self
            
            return cell!
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if !editSegue {
            if profileTap {
                guard let profileVC = segue.destination as? ProfileViewController else {return}
                profileVC.fromPostPage = true
                profileVC.currentUsername = tappedUsername!
            }
            else if vmrComment != nil{
                if vmrComment!.nestedLevel == 0 {
                    guard let childPageVC = segue.destination as? ChildPageViewController else {return}
                    let view = childPageVC.view //to load the view
                    childPageVC.setUpChildPage(post: currentPost, comment: vmrComment!, userAction: currentUserAction, parentPage: self)
                }
                else {
                    guard let grandchildPageVC = segue.destination as? GrandchildPageViewController else {return}
                    let view = grandchildPageVC.view //to load the view
                    //grandchildPageVC.fromRoot = true
                    grandchildPageVC.setUpGrandchildPage(post: currentPost, comment: vmrComment!, userAction: currentUserAction, parentPage: self)
                }
            }
            
        }
        else {
            guard let editPostVC = segue.destination as? EditPostViewController else {return}
            let view = editPostVC.view
            
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PostCardTableViewCell {
                if currentPost.redimg.intValue % 10 == 1 && currentPost.blackimg.intValue % 10 == 1 {
                    editPostVC.setEditPage(postToEdit: currentPost, redImg: cell.redImage.image, blueImg: cell.blueImage.image, rootVC: self)
                }
                else if currentPost.redimg.intValue % 10 == 1 {
                    editPostVC.setEditPage(postToEdit: currentPost, redImg: cell.redImage.image, blueImg: nil, rootVC: self)
                }
                else if currentPost.blackimg.intValue % 10 == 1 {
                    editPostVC.setEditPage(postToEdit: currentPost, redImg: nil, blueImg: cell.blueImage.image, rootVC: self)
                }
                else {
                    editPostVC.setEditPage(postToEdit: currentPost, redImg: nil, blueImg: nil, rootVC: self)
                }
            }
            
            
            
        }
        
    }
    
    func goToProfile(profileUsername: String) {
        if textInput.text != nil && textInput.text!.count > 0 {
            //textInput.resignFirstResponder()
            let alert = UIAlertController(title: nil, message: "Are you sure? The text you entered will be discarded.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                self.textInput.text = ""
                self.profileTap = true
                self.vmrTap = false
                self.tappedUsername = profileUsername
                //try not to send self, just to avoid retain cycles(depends on how you handle the code on the next controller)
                self.performSegue(withIdentifier: "rootToProfile", sender: self)
            }))
            self.present(alert, animated: true, completion: nil)
            
        }
        else {
            profileTap = true
            vmrTap = false
            tappedUsername = profileUsername
            //try not to send self, just to avoid retain cycles(depends on how you handle the code on the next controller)
            performSegue(withIdentifier: "rootToProfile", sender: self)
        }
    }
    
    func resizePostCardOnVote(red : Bool){
        
        if red { //voted left side
            switch currentUserAction.votedSide {
            case "none":
                //this is a new vote; send notification to author
                sendPostVoteNotification()
                
                VSVersusAPIClient.default().vGet(e: nil, c: currentPost.post_id, d: nil, a: "v", b: "r")
                currentPost.redcount = NSNumber(value: currentPost.redcount.intValue + 1)
                showToast(message: "Vote Submitted", length: 14)
            case "BLK":
                VSVersusAPIClient.default().vGet(e: nil, c: currentPost.post_id, d: nil, a: "v", b: "br")
                currentPost.blackcount = NSNumber(value: currentPost.blackcount.intValue - 1)
                currentPost.redcount = NSNumber(value: currentPost.redcount.intValue + 1)
                showToast(message: "Vote Submitted", length: 14)
            default:
                break;
            }
            
            currentUserAction.votedSide = "RED"
        }
        else { //voted right side, black/blue
            switch currentUserAction.votedSide {
            case "none":
                //this is a new vote; send notification to author
                sendPostVoteNotification()
                
                VSVersusAPIClient.default().vGet(e: nil, c: currentPost.post_id, d: nil, a: "v", b: "b")
                currentPost.blackcount = NSNumber(value: currentPost.blackcount.intValue + 1)
                showToast(message: "Vote Submitted", length: 14)
            case "RED":
                VSVersusAPIClient.default().vGet(e: nil, c: currentPost.post_id, d: nil, a: "v", b: "rb")
                currentPost.redcount = NSNumber(value: currentPost.redcount.intValue - 1)
                currentPost.blackcount = NSNumber(value: currentPost.blackcount.intValue + 1)
                showToast(message: "Vote Submitted", length: 14)
            default:
                break;
            }
            
            currentUserAction.votedSide = "BLK"
        }
        
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        
        currentUserAction.changed = true
        
    }
    
    func commentHearted(commentID: String) {
        print("votedCommentID: \(commentID)")
        if let thisComment = nodeMap[commentID]?.nodeContent {
            if let prevAction = currentUserAction.actionRecord[commentID] {
                switch prevAction {
                case "U":
                    VSVersusAPIClient.default().vGet(e: nil, c: commentID, d: nil, a: "v", b: "un")
                    currentUserAction.actionRecord[commentID] = "N"
                    thisComment.upvotes -= 1
                case "D":
                    VSVersusAPIClient.default().vGet(e: nil, c: commentID, d: nil, a: "v", b: "du")
                    currentUserAction.actionRecord[commentID] = "U"
                    thisComment.downvotes -= 1
                    thisComment.upvotes += 1
                default:
                    VSVersusAPIClient.default().vGet(e: nil, c: commentID, d: nil, a: "v", b: "u")
                    currentUserAction.actionRecord[commentID] = "U"
                    thisComment.upvotes += 1
                }
            }
            else {
                //a new vote; send notification to author and increase their influence accordingly
                sendCommentUpvoteNotification(upvotedComment: nodeMap[commentID]!.nodeContent)
                
                VSVersusAPIClient.default().vGet(e: nil, c: commentID, d: nil, a: "v", b: "u")
                VSVersusAPIClient.default().vGet(e: nil, c: thisComment.author, d: nil, a: "ui", b: "1")
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
                    VSVersusAPIClient.default().vGet(e: nil, c: commentID, d: nil, a: "v", b: "dn")
                    currentUserAction.actionRecord[commentID] = "N"
                    thisComment.downvotes -= 1
                case "U":
                    VSVersusAPIClient.default().vGet(e: nil, c: commentID, d: nil, a: "v", b: "ud")
                    currentUserAction.actionRecord[commentID] = "D"
                    thisComment.upvotes -= 1
                    thisComment.downvotes += 1
                default:
                    if (thisComment.upvotes == 0 && thisComment.downvotes + 1 <= 10) || (thisComment.upvotes * 10 >= thisComment.downvotes + 1) {
                        VSVersusAPIClient.default().vGet(e: nil, c: commentID, d: nil, a: "v", b: "dci")
                    }
                    else {
                        VSVersusAPIClient.default().vGet(e: nil, c: commentID, d: nil, a: "v", b: "d")
                    }
                    currentUserAction.actionRecord[commentID] = "D"
                    thisComment.downvotes += 1
                }
            }
            else {
                //a new vote; send notification to author and increase their influence accordingly
                sendCommentUpvoteNotification(upvotedComment: nodeMap[commentID]!.nodeContent)
                
                if (thisComment.upvotes == 0 && thisComment.downvotes + 1 <= 10) || (thisComment.upvotes * 10 >= thisComment.downvotes + 1) {
                    VSVersusAPIClient.default().vGet(e: nil, c: commentID, d: nil, a: "v", b: "dci")
                }
                else {
                    VSVersusAPIClient.default().vGet(e: nil, c: commentID, d: nil, a: "v", b: "d")
                }
                currentUserAction.actionRecord[commentID] = "D"
                thisComment.downvotes += 1
            }
        }
        
        currentUserAction.changed = true
    }
    
    @IBAction func textChangeListener(_ sender: Any) {
        
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
    
    
    @IBAction func sendButtonTapped(_ sender: Any) {
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
                        
                        VSVersusAPIClient.default().commentputPost(body: newComment.getPutModel(), c: newComment.comment_id, a: "put", b: "vscomment").continueWith(block:) {(task: AWSTask) -> AnyObject? in
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
                                
                                VSVersusAPIClient.default().vGet(e: nil, c: self.currentPost.post_id, d: currentReplyTargetID!, a: "v", b: "cm") //ps increment for comment submission
                                self.sendCommentReplyNotification(replyTargetComment: self.nodeMap[currentGrandchildRealTargetID!]!.nodeContent)
                                
                            }
                            return nil
                        }
                        
                        
                    }
                    else { //a reply to a root comment or a child comment
                        var rootID : String!
                        let replyTarget = nodeMap[currentReplyTargetID!]!.nodeContent
                        let targetNestedLevel = replyTarget.nestedLevel
                        if targetNestedLevel == 0 { //reply to a root comment
                            rootID = "0"
                        }
                        else { //reply to a child comment
                            rootID = replyTarget.parent_id
                        }
                        
                        let newComment = VSComment(username: UserDefaults.standard.string(forKey: "KEY_USERNAME")!, parentID: currentReplyTargetID!, postID: currentPost.post_id, newContent: text, rootID: rootID)
                        
                        newComment.nestedLevel = targetNestedLevel! + 1 //root comment in root page has nested level of 0
                        
                        
                        VSVersusAPIClient.default().commentputPost(body: newComment.getPutModel(), c: newComment.comment_id, a: "put", b: "vscomment").continueWith(block:) {(task: AWSTask) -> AnyObject? in
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
                                
                                VSVersusAPIClient.default().vGet(e: nil, c: self.currentPost.post_id, d: currentReplyTargetID!, a: "v", b: "cm") //ps increment for comment submission
                                self.sendCommentReplyNotification(replyTargetComment: replyTarget)
                                
                            }
                            return nil
                        }
                        
                    }
                }
                else {
                    // a root comment to the post
                    let newComment = VSComment(username: UserDefaults.standard.string(forKey: "KEY_USERNAME")!, parentID: currentPost.post_id, postID: currentPost.post_id, newContent: text, rootID: "0")
                    newComment.nestedLevel = 0 //root comment in root page has nested level of 0
                    
                    VSVersusAPIClient.default().commentputPost(body: newComment.getPutModel(), c: newComment.comment_id, a: "put", b: "vscomment").continueWith(block:) {(task: AWSTask) -> AnyObject? in
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
                            
                            VSVersusAPIClient.default().vGet(e: nil, c: self.currentPost.post_id, d: nil, a: "v", b: "cm") //ps increment for comment submission
                            self.sendRootCommentNotification()
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
    
    func sendRootCommentNotification(){
        if currentPost.author != "deleted" && currentPost.author != UserDefaults.standard.string(forKey: "KEY_USERNAME")! {
            var nKey = currentPost.post_id+":"+sanitizeContentForURL(content: currentPost.redname)+":"+sanitizeContentForURL(content:currentPost.blackname)
            let postAuthorPath = getUsernameHash(username: currentPost.author) + "/" + currentPost.author + "/n/r/" + nKey
            ref.child(postAuthorPath).child(UserDefaults.standard.string(forKey: "KEY_USERNAME")!).setValue(Int(NSDate().timeIntervalSince1970))
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
    
    func replyButtonTapped(replyTarget: VSComment, cell: CommentCardTableViewCell) {
        let row = tableView.indexPath(for: cell)!.row
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
        if textInput.text != nil && textInput.text!.count > 0 {
            //textInput.resignFirstResponder()
            let alert = UIAlertController(title: nil, message: "Are you sure? The text you entered will be discarded.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                self.textInput.text = ""
                self.vmrTap = true
                self.profileTap = false
                self.vmrComment = topCardComment
                if topCardComment.nestedLevel == 0 {
                    //go to child page
                    self.performSegue(withIdentifier: "rootToChild", sender: self)
                }
                else {
                    //go to grandchild page
                    self.performSegue(withIdentifier: "rootToGrandchild", sender: self)
                }
            }))
            self.present(alert, animated: true, completion: nil)
        }
        else {
            vmrTap = true
            profileTap = false
            vmrComment = topCardComment
            if topCardComment.nestedLevel == 0 {
                //go to child page
                performSegue(withIdentifier: "rootToChild", sender: self)
            }
            else {
                //go to grandchild page
                performSegue(withIdentifier: "rootToGrandchild", sender: self)
            }
        }
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if grandchildRealTargetID != nil {
            return range.intersection(NSMakeRange(0, grandchildReplyTargetAuthor!.count+2)) == nil
        }
        return true
    }
    
    func presentSortMenu(sortButtonLabel: UILabel){
        let alertController = UIAlertController(title: "SORT BY", message: nil, preferredStyle: .actionSheet)
        //alertController.setValue(0, forKey: "titleTextAlignment")
        alertController.popoverPresentationController?.sourceView = sortButtonLabel
        alertController.popoverPresentationController?.sourceRect = sortButtonLabel.bounds
        
        let mostRecent = UIAlertAction(title: "Most Recent", style: .default) { (_) in
            sortButtonLabel.setPostPageSortLabel(imageName: "sort_Most Recent", suffix: " Most Recent")
            self.sortType = self.MOST_RECENT
            self.sortTypeString = "Most Recent"
            self.sortRefresh(8)
        }
        let icon_mostRecent = UIImage(named: "sort_Most Recent")
        mostRecent.setValue(icon_mostRecent, forKey: "image")
        mostRecent.setValue(0, forKey: "titleTextAlignment")
        
        let popular = UIAlertAction(title: "Popular", style: .default) { (_) in
            sortButtonLabel.setPostPageSortLabel(imageName: "sort_Popular", suffix: " Popular")
            self.sortType = self.POPULAR
            self.sortTypeString = "Popular"
            self.sortRefresh(8)
        }
        let icon_popular = UIImage(named: "sort_Popular")
        popular.setValue(icon_popular, forKey: "image")
        popular.setValue(0, forKey: "titleTextAlignment")
        
        let chronological = UIAlertAction(title: "Chronological", style: .default) { (_) in
            sortButtonLabel.setPostPageSortLabel(imageName: "sort_Chronological", suffix: " Chronological")
            self.sortType = self.CHRONOLOGICAL
            self.sortTypeString = "Chronological"
            self.sortRefresh(8)
        }
        let icon_chronological = UIImage(named: "sort_Chronological")
        chronological.setValue(icon_chronological, forKey: "image")
        chronological.setValue(0, forKey: "titleTextAlignment")
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addAction(mostRecent)
        alertController.addAction(popular)
        alertController.addAction(chronological)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true) {
            // ...
        }
    }
    
    override func shouldPopOnBackButton() -> Bool {
        if textInput.text != nil && textInput.text!.count > 0 {
            //textInput.resignFirstResponder()
            let alert = UIAlertController(title: nil, message: "Are you sure? The text you entered will be discarded.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                self.textInput.text = ""
                _ = self.navigationController?.popViewController(animated: true)
            }))
            self.present(alert, animated: true, completion: nil)
            
            return false
        }
        else {
            return true
        }
    }
    
    func startIndicator() {
        DispatchQueue.main.async {
            if !self.refreshControl.isRefreshing {
                if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PostCardTableViewCell {
                    cell.startIndicator()
                }
            }
        }
    }
    
    func stopIndicator() {
        DispatchQueue.main.async {
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PostCardTableViewCell {
                cell.stopIndicator()
            }
        }
    }

}
