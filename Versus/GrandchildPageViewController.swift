//
//  RootPageViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 8/3/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import FirebaseDatabase
import PopupDialog


class GrandchildPageViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PostPageDelegator, UITextViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textInput: UITextView!
    @IBOutlet weak var textInputContainer: UIView!
    @IBOutlet weak var textInputContainerBottom: NSLayoutConstraint!
    @IBOutlet weak var commentSendButton: UIButton!
    @IBOutlet weak var replyTargetLabel: UILabel!
    
    @IBOutlet weak var replyTargetResetButton: UIButton!
    
    var currentPost : PostObject!
    var comments = [VSComment]()
    
    var nodeMap = [String : VSCNode]()
    var currentUserAction : UserAction!
    var tappedUsername : String?
    var keyboardIsShowing = false
    var grandchildRealTargetID, grandchildReplyTargetAuthor: String?
    var replyTargetRowNumber : Int?
    var ref: DatabaseReference!
    var expandedCells = NSMutableSet()
    var topCardComment : VSComment!
    var fromRoot : Bool!
    var parentRootVC : RootPageViewController?
    var parentChildVC : ChildPageViewController?
    
    var fromIndex : Int?
    var nowLoading = false
    var loadThreshold = 8
    let retrievalSize = 16
    var reactivateLoadMore = false
    var fromIndexIncrement : Int?
    var topicComment : VSComment?
    
    var medalWinnersList = [String : String]() //commentID : medalType
    var winnerTreeRoots = NSMutableSet() //HashSet to prevent duplicate addition of medal winner's root into rootComments
    
    let goldPoints = 30
    let silverPoints = 15
    let bronzePoints = 5
    
    var sortType = 0
    let POPULAR = 0
    let MOST_RECENT = 1
    let CHRONOLOGICAL = 2
    var sortTypeString = "Popular"
    let placeholder = "Join the discussion!"
    
    var blockedUsernames = NSMutableSet()
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
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
    
    var paddingBottom : CGFloat = 0.0
    
    override func viewDidLayoutSubviews() {
        if #available(iOS 11.0, *) {
            paddingBottom = view.safeAreaInsets.bottom
        }
        
    }
    
    override func viewDidLoad() {
        print("gc loaded")
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
        
        let color = UIColor(red: 186/255, green: 186/255, blue: 186/255, alpha: 1.0).cgColor
        textInput.layer.borderColor = color
        textInput.layer.borderWidth = 0.5
        textInput.layer.cornerRadius = 5
        textInput.text = placeholder
        textInput.textColor = UIColor.lightGray
        
        //tableView.allowsSelection = false
        ref = Database.database().reference()
        
        // Add Refresh Control to Table View
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            refreshControl.tag = 420
            tableView.addSubview(refreshControl)
        }
        
        // Configure Refresh Control
        refreshControl.addTarget(self, action: #selector(refreshList(_:)), for: .valueChanged)
    }
    
    @objc private func refreshList(_ sender: Any) {
        if !keyboardIsShowing && comments.count > 1 && currentPost != nil && currentUserAction != nil && topCardComment != nil{
            comments.removeAll()
            tableView.reloadData()
            if fromRoot {
                setUpGrandchildPage(post: currentPost, comment: topCardComment, userAction: currentUserAction, parentPage: parentRootVC)
            }
            else {
                setUpGrandchildPage(post: currentPost, comment: topCardComment, userAction: currentUserAction, parentPage: parentChildVC, grandparentPage: parentRootVC)
            }
        }
        else {
            refreshControl.endRefreshing()
        }
    }
    
    func sortRefresh(_ sender: Any){
        fromIndex = 0
        
        comments.removeAll()
        
        winnerTreeRoots.removeAllObjects()
        
        topicComment = nil
        expandedCells.removeAllObjects()
        nowLoading = false
        
        comments.append(topCardComment)
        tableView.reloadData()
        
        if sortType == POPULAR {
            setMedals()
        }
        else {
            commentsQuery()
        }
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
        
        
        
        if var viewControllers = navigationController?.viewControllers {
            if parentRootVC == nil && parentChildVC == nil {
                if viewControllers.count > 0 {
                    parentRootVC = storyboard!.instantiateViewController(withIdentifier: "rootPage") as? RootPageViewController
                    let rView = parentRootVC?.view
                    parentChildVC = storyboard!.instantiateViewController(withIdentifier: "childPage") as? ChildPageViewController
                    let cView = parentChildVC?.view
                    viewControllers.insert(parentChildVC!, at: viewControllers.count-1)
                    viewControllers.insert(parentRootVC!, at: viewControllers.count-2)
                    navigationController?.viewControllers = viewControllers
                    
                    parentRootVC?.setUpRootPage(post: currentPost, userAction: currentUserAction, fromCreatePost: false)
                    
                    VSVersusAPIClient.default().commentGet(a: "c", b: topCardComment!.parent_id).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                        if task.error != nil {
                            DispatchQueue.main.async {
                                print(task.error!)
                            }
                        }
                        else {
                            if let commentResult = task.result { //this parent (child) of the clicked comment (grandchild), for the top card
                                
                                self.parentChildVC?.setUpChildPage(post: self.currentPost, comment: VSComment(itemSource: commentResult.source!, id: commentResult.id!), userAction: self.currentUserAction, parentPage: self.parentRootVC)
                            }
                        }
                        return nil
                    }
                    
                }
            }
        }
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textInput.resignFirstResponder()
        
        if currentUserAction.changed {
            if isMovingFromParentViewController && (parentRootVC != nil || parentChildVC != nil) {
                if fromRoot {
                    parentRootVC!.tableView.reloadData()
                }
                else {
                    parentChildVC!.tableView.reloadData()
                }
            }
            
            VSVersusAPIClient.default().recordPost(body: currentUserAction.getRecordPutModel(), a: "rcp", b: currentUserAction.id).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                if task.error != nil {
                    DispatchQueue.main.async {
                        print(task.error!)
                    }
                }
                else {
                    self.appDelegate.userAction = nil
                }
                return nil
            }
        }
        
        NotificationCenter.default.removeObserver(self)
        
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        /*
        if #available(iOS 10.0, *) {
            tableView.refreshControl = nil
        } else {
            if let tagview = tableView.viewWithTag(420) {
                tagview.removeFromSuperview()
            }
        }
        */
        keyboardIsShowing = true
        let userInfo: NSDictionary = notification.userInfo! as NSDictionary
        let keyboardInfo = userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue
        let keyboardSize = keyboardInfo.cgRectValue.size
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        tableView.contentInset = contentInsets
        tableView.scrollIndicatorInsets = contentInsets
        
        textInputContainerBottom.constant = -keyboardSize.height + paddingBottom
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        /*
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            refreshControl.tag = 420
            tableView.addSubview(refreshControl)
        }
        */
        keyboardIsShowing = false
        tableView.contentInset = .zero
        tableView.scrollIndicatorInsets = .zero
        textInputContainerBottom.constant = 0
        //textInput.text = ""
        /*
        grandchildRealTargetID = nil
        grandchildReplyTargetAuthor = nil
        replyTargetLabel.text = ""
        */
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.cellForRow(at: indexPath)?.selectionStyle = UITableViewCellSelectionStyle.none
        }
        
    }
    
    @IBAction func replyTargetResetTapped(_ sender: UIButton) {
        replyTargetResetButton.isHidden = true
        grandchildRealTargetID = nil
        grandchildReplyTargetAuthor = nil
        replyTargetLabel.text = ""
        
        textInput.text = placeholder
        textInput.textColor = UIColor.lightGray
        commentSendButton.isEnabled = false
        commentSendButton.setBackgroundImage(#imageLiteral(resourceName: "ic_send_grey"), for: .normal)
        textInput.selectedTextRange = textInput.textRange(from: textInput.beginningOfDocument, to: textInput.beginningOfDocument)
    }
    
    func resetCommentInput() {
        replyTargetResetButton.isHidden = true
        grandchildRealTargetID = nil
        grandchildReplyTargetAuthor = nil
        replyTargetLabel.text = ""
        
        textInput.text = placeholder
        textInput.textColor = UIColor.lightGray
        commentSendButton.isEnabled = false
        commentSendButton.setBackgroundImage(#imageLiteral(resourceName: "ic_send_grey"), for: .normal)
        textInput.selectedTextRange = textInput.textRange(from: textInput.beginningOfDocument, to: textInput.beginningOfDocument)
    }
    
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if keyboardIsShowing {
            if scrollView is UITableView {
                textInputContainer.isHidden = true
                replyTargetLabel.isHidden = true
                replyTargetResetButton.isHidden = true
            }
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        textInputContainer.isHidden = false
        replyTargetLabel.isHidden = false
        if replyTargetLabel.text != nil && replyTargetLabel.text!.count > 0 {
            replyTargetResetButton.isHidden = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func commentClickSetUpGrandchildPage (post : PostObject, comment : VSComment, userAction : UserAction, topicComment : VSComment) {
        sortType = CHRONOLOGICAL
        sortTypeString = "Chronological"
        fromRoot = false
        self.topicComment = topicComment
        parentChildVC = nil
        parentRootVC = nil
        
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
        comments.append(topicComment)
        nodeMap[topicComment.comment_id] = VSCNode(comment: topicComment)
        currentUserAction = userAction
        nodeMap[comment.comment_id] = VSCNode(comment: comment)
        print("setup grandchild page query called")
        setMedals() //this function will call commentsQuery() upon completion
        
    }
    
    func setUpGrandchildPage(post : PostObject, comment : VSComment, userAction : UserAction, parentPage : RootPageViewController?){
        sortType = CHRONOLOGICAL
        sortTypeString = "Chronological"
        fromRoot = true
        topicComment = nil
        parentRootVC = parentPage
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
        print("setup grandchild page query called")
        setMedals() //this function will call commentsQuery() upon completion
        
    }
    
    func setUpGrandchildPage(post : PostObject, comment : VSComment, userAction : UserAction, parentPage : ChildPageViewController?, grandparentPage: RootPageViewController?){
        sortType = CHRONOLOGICAL
        sortTypeString = "Chronological"
        fromRoot = false
        topicComment = nil
        parentChildVC = parentPage
        parentRootVC = grandparentPage
        
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
        print("setup grandchild page query called")
        setMedals() //this function will call commentsQuery() upon completion
        
    }
    
    func getNestedLevel(commentModel : VSCommentsListModel_hits_hits_item__source) -> Int {
        if commentModel.r != "0" && commentModel.pr == topCardComment.comment_id {
            return 5
        }
        return -1 //only level 5 comments for grandchild page
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
        VSVersusAPIClient.default().commentslistGet(c: nil, d: nil, a: "m", b: currentPost.post_id).continueWith(block:) {(task: AWSTask) -> AnyObject? in
            if task.error != nil {
                DispatchQueue.main.async {
                    print(task.error!)
                }
            }
            else {
                
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
                        
                        if self.getNestedLevel(commentModel: item.source!) == 5 {
                            if !self.winnerTreeRoots.contains(item.id) {
                                self.winnerTreeRoots.add(item.id!)
                                let newComment = VSComment(itemSource: item.source!, id: item.id!)
                                newComment.nestedLevel = 5
                                if self.topicComment == nil || self.topicComment?.comment_id != item.id! {
                                    self.comments.append(newComment)
                                    self.nodeMap[newComment.comment_id] = VSCNode(comment: newComment)
                                }
                            }
                        }
                        
                        i += 1
                    }
                }
                
                self.commentsQuery()
                
            }
            return nil
        }
        
    }
    
    func commentsQuery(){
        startIndicator()
        
        if fromIndex == nil {
            fromIndex = 0
        }
        
        if fromIndex == 0  {
            if let blockList = UserDefaults.standard.object(forKey: "KEY_BLOCKS") as? [String] {
                if blockedUsernames.count > 0 {
                    blockedUsernames.removeAllObjects()
                }
                blockedUsernames.addObjects(from: blockList)
            }
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
        VSVersusAPIClient.default().commentslistGet(c: topCardComment.comment_id, d: ascORdesc, a: queryType, b: "\(fromIndex!)").continueWith(block:) {(task: AWSTask) -> AnyObject? in
            print("gc commentQuery with fromIndex == \(self.fromIndex!)")
            if task.error != nil {
                DispatchQueue.main.async {
                    print(task.error!)
                }
            }
            else {
                
                if let rootQueryResults = task.result?.hits?.hits {
                    for item in rootQueryResults {
                        let comment = VSComment(itemSource: item.source!, id: item.id!)
                        if !(self.winnerTreeRoots.contains(comment.comment_id) || (self.topicComment != nil && self.topicComment!.comment_id == comment.comment_id))  {
                            comment.nestedLevel = 5
                            self.comments.append(comment)
                            self.nodeMap[comment.comment_id] = VSCNode(comment: comment)
                        }
                        
                    }
                    
                    DispatchQueue.main.async {
                        if self.refreshControl.isRefreshing {
                            self.refreshControl.endRefreshing()
                        }
                        
                        self.tableView.reloadData()
                        
                        self.fromIndex! += rootQueryResults.count
                        if rootQueryResults.count == self.retrievalSize {
                            self.nowLoading = false
                        }
                        else {
                            self.nowLoading = true
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
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 138
        }
        
        if expandedCells.contains(indexPath.row) {
            return 303
        }
        else {
            return 90
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TopCard", for: indexPath) as? CommentCardTableViewCell
            let comment = comments[indexPath.row]
            if let selection = currentUserAction.actionRecord[comment.comment_id] {
                switch selection {
                case "N":
                    cell!.setTopCardCell(comment: comment, row: indexPath.row, sortType: sortTypeString)
                case "U":
                    cell!.setTopCardCellWithSelection(comment: comment, hearted: true, row: indexPath.row, sortType: sortTypeString)
                case "D":
                    cell!.setTopCardCellWithSelection(comment: comment, hearted: false, row: indexPath.row, sortType: sortTypeString)
                default:
                    cell!.setTopCardCell(comment: comment, row: indexPath.row, sortType: sortTypeString)
                }
            }
            else {
                cell!.setTopCardCell(comment: comment, row: indexPath.row, sortType: sortTypeString)
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
        else {
            let comment = comments[indexPath.row]
            
            if blockedUsernames.contains(comment.author) {
                let cell = tableView.dequeueReusableCell(withIdentifier: "blockedComment", for: indexPath) as? BlockedCommentTableViewCell
                cell!.comment = comment
                cell!.rowNumber = indexPath.row
                cell!.delegate = self
                
                return cell!
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCard", for: indexPath) as? CommentCardTableViewCell
                
                if let selection = currentUserAction.actionRecord[comment.comment_id] {
                    switch selection {
                    case "N":
                        cell!.setCell(comment: comment, indent: 0, row: indexPath.row)
                    case "U":
                        cell!.setCellWithSelection(comment: comment, indent: 0, hearted: true, row: indexPath.row)
                    case "D":
                        cell!.setCellWithSelection(comment: comment, indent: 0, hearted: false, row: indexPath.row)
                    default:
                        cell!.setCell(comment: comment, indent: 0, row: indexPath.row)
                    }
                }
                else {
                    cell!.setCell(comment: comment, indent: 0, row: indexPath.row)
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
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let profileVC = segue.destination as? ProfileViewController else {return}
        profileVC.fromPostPage = true
        profileVC.currentUsername = tappedUsername!
        
    }
    
    func goToProfile(profileUsername: String) {
        if textInput.text != nil && textInput.textColor != UIColor.lightGray && !(grandchildReplyTargetAuthor != nil && textInput.text!.count <= grandchildReplyTargetAuthor!.count + 2) {
            //textInput.resignFirstResponder()
            let alert = UIAlertController(title: nil, message: "Are you sure? The text you entered will be discarded.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                self.textInput.text = ""
                self.commentSendButton.isEnabled = false
                self.commentSendButton.setBackgroundImage(#imageLiteral(resourceName: "ic_send_grey"), for: .normal)
                self.tappedUsername = profileUsername
                //try not to send self, just to avoid retain cycles(depends on how you handle the code on the next controller)
                self.performSegue(withIdentifier: "grandchildToProfile", sender: self)
            }))
            self.present(alert, animated: true, completion: nil)
        }
        else {
            tappedUsername = profileUsername
            //try not to send self, just to avoid retain cycles(depends on how you handle the code on the next controller)
            performSegue(withIdentifier: "grandchildToProfile", sender: self)
        }
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
            if fromRoot {
                if parentRootVC != nil {
                    if let node = parentRootVC!.nodeMap[thisComment.comment_id] {
                        node.votedUpdate(upvotes: thisComment.upvotes, downvotes: thisComment.downvotes)
                    }
                }
            }
            else {
                if parentRootVC != nil {
                    if let node = parentRootVC!.nodeMap[thisComment.comment_id] {
                        node.votedUpdate(upvotes: thisComment.upvotes, downvotes: thisComment.downvotes)
                    }
                }
                
                if parentChildVC != nil {
                    if let node = parentChildVC!.nodeMap[thisComment.comment_id] {
                        node.votedUpdate(upvotes: thisComment.upvotes, downvotes: thisComment.downvotes)
                    }
                }
            }
            
        }
        
        currentUserAction.changed = true
        appDelegate.userAction = currentUserAction
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
            
            if fromRoot {
                if parentRootVC != nil {
                    if let node = parentRootVC!.nodeMap[thisComment.comment_id] {
                        node.votedUpdate(upvotes: thisComment.upvotes, downvotes: thisComment.downvotes)
                    }
                }
            }
            else {
                if parentRootVC != nil {
                    if let node = parentRootVC!.nodeMap[thisComment.comment_id] {
                        node.votedUpdate(upvotes: thisComment.upvotes, downvotes: thisComment.downvotes)
                    }
                }
                
                if parentChildVC != nil {
                    if let node = parentChildVC!.nodeMap[thisComment.comment_id] {
                        node.votedUpdate(upvotes: thisComment.upvotes, downvotes: thisComment.downvotes)
                    }
                }
            }
        }
        
        currentUserAction.changed = true
        appDelegate.userAction = currentUserAction
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        // Combine the textView text and the replacement text to
        // create the updated text string
        let currentText:String = textView.text
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)
        
        if grandchildReplyTargetAuthor != nil {
            if updatedText.count > grandchildReplyTargetAuthor!.count + 2 && !updatedText[grandchildReplyTargetAuthor!.count + 2 ... updatedText.count - 1].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                //turn autocapitalization to sentence mode
                //textView.autocapitalizationType = .sentences
                //textView.reloadInputViews()
                
                textView.textColor = UIColor.black
                commentSendButton.isEnabled = true
                commentSendButton.setBackgroundImage(#imageLiteral(resourceName: "ic_send_blue"), for: .normal)
            }
            else {
                //force capitalization for first character
                //textView.autocapitalizationType = .words
                //textView.reloadInputViews()
                
                commentSendButton.isEnabled = false
                commentSendButton.setBackgroundImage(#imageLiteral(resourceName: "ic_send_grey"), for: .normal)
            }
            
            return range.intersection(NSMakeRange(0, grandchildReplyTargetAuthor!.count+2)) == nil
        }
        
        // If updated text view will be empty, add the placeholder
        // and set the cursor to the beginning of the text view
        if updatedText.isEmpty {
            //force capitalization for first character
            textView.autocapitalizationType = .words
            textView.reloadInputViews()
            
            textView.text = placeholder
            textView.textColor = UIColor.lightGray
            commentSendButton.isEnabled = false
            commentSendButton.setBackgroundImage(#imageLiteral(resourceName: "ic_send_grey"), for: .normal)
            
            textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
        }
            
            // Else if the text view's placeholder is showing and the
            // length of the replacement string is greater than 0, set
            // the text color to black then set its text to the
            // replacement string
        else if textView.textColor == UIColor.lightGray && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            //turn autocapitalization to sentence mode
            textView.autocapitalizationType = .sentences
            textView.reloadInputViews()
            
            textView.textColor = UIColor.black
            textView.text = text
            commentSendButton.isEnabled = true
            commentSendButton.setBackgroundImage(#imageLiteral(resourceName: "ic_send_blue"), for: .normal)
        }
            
            // For every other case, the text should change with the usual
            // behavior...
        else {
            return true
        }
        
        // ...otherwise return false since the updates have already
        // been made
        return false
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
        }
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if self.view.window != nil {
            if grandchildReplyTargetAuthor == nil {
                if textView.selectedTextRange?.end != textView.beginningOfDocument && textView.textColor == UIColor.lightGray {
                    textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
                }
            }
            else {
                if let offsetPosition = textView.position(from: textView.beginningOfDocument, offset: grandchildReplyTargetAuthor!.count+2) {
                    if textView.text.count == grandchildReplyTargetAuthor!.count + 2 && textView.selectedTextRange?.end != offsetPosition {
                        textView.selectedTextRange = textView.textRange(from: offsetPosition, to: offsetPosition)
                    }
                }
            }
            
        }
    }
    
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        if textInput.textColor != UIColor.lightGray {
            let currentGrandchildRealTargetID = grandchildRealTargetID
            
            if let text = textInput.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
                if text.count > 0 {
                    
                    resetCommentInput()
                    /*
                    textInput.text = placeholder
                    textInput.textColor = UIColor.lightGray
                    commentSendButton.isEnabled = false
                    commentSendButton.setBackgroundImage(#imageLiteral(resourceName: "ic_send_grey"), for: .normal)
                    */
                    textInput.resignFirstResponder()
                    
                    if currentGrandchildRealTargetID != nil {
                        
                        // an @reply at a grandchild comment. The actual parent of this comment will be the child comment.
                        
                        let newComment = VSComment(username: UserDefaults.standard.string(forKey: "KEY_USERNAME")!, parentID: topCardComment.comment_id, postID: topCardComment.post_id, newContent: text, rootID: topCardComment.parent_id)
                        
                        newComment.nestedLevel = 5
                        
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
                                
                                VSVersusAPIClient.default().vGet(e: nil, c: self.currentPost.post_id, d: self.topCardComment.comment_id, a: "v", b: "cm") //ps increment for comment submission
                                
                                if self.fromRoot {
                                    if self.parentRootVC != nil {
                                        if let node = self.parentRootVC!.nodeMap[self.topCardComment.comment_id] {
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
                                            self.parentRootVC!.setCommentsFromChildPage()
                                        }
                                    }
                                }
                                else {
                                    if self.parentRootVC != nil {
                                        if let node = self.parentRootVC!.nodeMap[self.topCardComment.comment_id] {
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
                                            self.parentRootVC!.setCommentsFromChildPage()
                                        }
                                    }
                                    
                                    if self.parentChildVC != nil {
                                        if let node = self.parentChildVC!.nodeMap[self.topCardComment.comment_id] {
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
                                            self.parentChildVC!.setCommentsFromChildPage()
                                        }
                                    }
                                }
                                
                                self.sendCommentReplyNotification(replyTargetComment: self.nodeMap[currentGrandchildRealTargetID!]!.nodeContent)
                            }
                            return nil
                        }
                        
                        
                    }
                    else {
                        // a reply to the top card
                        let newComment = VSComment(username: UserDefaults.standard.string(forKey: "KEY_USERNAME")!, parentID: topCardComment.comment_id, postID: topCardComment.post_id, newContent: text, rootID: topCardComment.parent_id)
                        newComment.nestedLevel = 5
                        
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
                                    self.comments.insert(newComment, at: 1)
                                    self.tableView.insertRows(at: [IndexPath(row: 1, section: 0)], with: .fade)
                                }
                                
                                VSVersusAPIClient.default().vGet(e: nil, c: self.currentPost.post_id, d: self.topCardComment.comment_id, a: "v", b: "cm") //ps increment for comment submission
                                
                                if self.fromRoot {
                                    if self.parentRootVC != nil {
                                        if let node = self.parentRootVC!.nodeMap[self.topCardComment.comment_id] {
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
                                            self.parentRootVC!.setCommentsFromChildPage()
                                        }
                                    }
                                }
                                else {
                                    if self.parentRootVC != nil {
                                        if let node = self.parentRootVC!.nodeMap[self.topCardComment.comment_id] {
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
                                            self.parentRootVC!.setCommentsFromChildPage()
                                        }
                                    }
                                    
                                    if self.parentChildVC != nil {
                                        if let node = self.parentChildVC!.nodeMap[self.topCardComment.comment_id] {
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
                                            self.parentChildVC!.setCommentsFromChildPage()
                                        }
                                    }
                                }
                                
                                self.sendCommentReplyNotification(replyTargetComment: self.topCardComment!)
                            }
                            return nil
                        }
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
        if grandchildRealTargetID != nil {
            return tableView.indexPathForSelectedRow
        }
        return indexPath
    }
    
    func replyButtonTapped(replyTarget: VSComment, cell: CommentCardTableViewCell) {
        
        let row = tableView.indexPath(for: cell)!.row
        replyTargetRowNumber = row
        
        if replyTarget.comment_id == topCardComment.comment_id {
            grandchildRealTargetID = nil
            grandchildReplyTargetAuthor = nil
            
            textInput.text = placeholder
            textInput.textColor = UIColor.lightGray
            textInput.selectedTextRange = textInput.textRange(from: textInput.beginningOfDocument, to: textInput.beginningOfDocument)
        }
        else if replyTarget.comment_id != topCardComment.comment_id {
            grandchildReplyTargetAuthor = replyTarget.author
            grandchildRealTargetID = replyTarget.comment_id
            
            textInput.text = "@"+grandchildReplyTargetAuthor! + " "
            textInput.textColor = .black
            textInput.selectedTextRange = textInput.textRange(from: textInput.endOfDocument, to: textInput.endOfDocument)
            textInput.autocapitalizationType = .sentences
            textInput.reloadInputViews()
        }
        
        textInput.becomeFirstResponder()
        replyTargetLabel.text = "Replying to: \(replyTarget.author)"
        replyTargetResetButton.isHidden = false
        
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
        //go to grandchild page
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
        if textInput.text != nil && textInput.textColor != UIColor.lightGray && !(grandchildReplyTargetAuthor != nil && textInput.text!.count <= grandchildReplyTargetAuthor!.count + 2) {
            //textInput.resignFirstResponder()
            let alert = UIAlertController(title: nil, message: "Are you sure? The text you entered will be discarded.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                self.textInput.text = ""
                self.commentSendButton.isEnabled = false
                self.commentSendButton.setBackgroundImage(#imageLiteral(resourceName: "ic_send_grey"), for: .normal)
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
                if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? CommentCardTableViewCell {
                    cell.startIndicator()
                }
            }
        }
        
    }
    
    func stopIndicator() {
        DispatchQueue.main.async {
            if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? CommentCardTableViewCell {
                cell.stopIndicator()
            }
        }
    }
    
    func blockedCardOverflow(comment: VSComment, sender: UIButton, row: Int) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.popoverPresentationController?.sourceView = sender
        alert.popoverPresentationController?.sourceRect = sender.bounds
        
        alert.addAction(UIAlertAction(title: "Unblock This User", style: .default, handler: { _ in
            // Prepare the popup assets
            let title = "Unblock this user?"
            let message = ""
            
            // Create the dialog
            let popup = PopupDialog(title: title, message: message)
            
            // Create buttons
            let buttonOne = DefaultButton(title: "No", action: nil)
            
            // This button will not the dismiss the dialog
            let buttonTwo = DefaultButton(title: "Yes") {
                var myUsername = UserDefaults.standard.string(forKey: "KEY_USERNAME")!
                
                var usernameHash : Int32
                if(myUsername.count < 5){
                    usernameHash = myUsername.hashCode()
                }
                else{
                    var hashIn = ""
                    hashIn.append(myUsername[0])
                    hashIn.append(myUsername[myUsername.count-2])
                    hashIn.append(myUsername[1])
                    hashIn.append(myUsername[myUsername.count-1])
                    
                    usernameHash = hashIn.hashCode()
                }
                
                let commentAuthor = comment.author
                
                let blockPath = "\(usernameHash)/\(myUsername)/blocked/\(commentAuthor)"
                Database.database().reference().child(blockPath).removeValue()
                
                var blockListArray = [String]()
                
                if let blockList = UserDefaults.standard.object(forKey: "KEY_BLOCKS") as? [String] {
                    blockListArray = blockList
                }
                
                var i = 0
                for username in blockListArray {
                    if username == commentAuthor {
                        blockListArray.remove(at: i)
                    }
                    i += 1
                }
                
                UserDefaults.standard.set(blockListArray, forKey: "KEY_BLOCKS")
                
                self.blockedUsernames.remove(commentAuthor)
                self.tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
                
                let str = "Unblocked \(commentAuthor)."
                self.showToast(message: str, length: str.count + 2)
            }
            
            popup.addButtons([buttonOne, buttonTwo])
            popup.buttonAlignment = .horizontal
            
            // Present dialog
            self.present(popup, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
        
        
        
    }
    
    
    
    func commentCardOverflow(comment: VSComment, sender: UIButton, row: Int) {
        if comment.author == UserDefaults.standard.string(forKey: "KEY_USERNAME") {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            alert.popoverPresentationController?.sourceView = sender
            alert.popoverPresentationController?.sourceRect = sender.bounds
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            if Date().timeIntervalSince(formatter.date(from: comment.time)!).isLess(than: 301) {
                alert.addAction(UIAlertAction(title: "Edit", style: .default, handler: { _ in
                    //handle comment edit
                    self.showEditCommentDialog(commentToEdit: comment, row: row)
                    
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                //handle comment delete
                VSVersusAPIClient.default().deleteGet(a: "cd", b: comment.comment_id)
                
                if self.comments[row].comment_id == comment.comment_id {
                    self.comments[row].author = "deleted"
                    self.nodeMap[comment.comment_id]?.nodeContent.author = "deleted"
                    self.tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
                }
                
            }))
            
            alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
            
        }
        else {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            alert.popoverPresentationController?.sourceView = sender
            alert.popoverPresentationController?.sourceRect = sender.bounds
            
            alert.addAction(UIAlertAction(title: "Block This User", style: .default, handler: { _ in
                // Prepare the popup assets
                let title = "Block this user?"
                let message = ""
                
                // Create the dialog
                let popup = PopupDialog(title: title, message: message)
                
                // Create buttons
                let buttonOne = DefaultButton(title: "No", action: nil)
                
                // This button will not the dismiss the dialog
                let buttonTwo = DefaultButton(title: "Yes") {
                    var myUsername = UserDefaults.standard.string(forKey: "KEY_USERNAME")!
                    
                    var usernameHash : Int32
                    if(myUsername.count < 5){
                        usernameHash = myUsername.hashCode()
                    }
                    else{
                        var hashIn = ""
                        hashIn.append(myUsername[0])
                        hashIn.append(myUsername[myUsername.count-2])
                        hashIn.append(myUsername[1])
                        hashIn.append(myUsername[myUsername.count-1])
                        
                        usernameHash = hashIn.hashCode()
                    }
                    let commentAuthor = comment.author
                    let blockPath = "\(usernameHash)/\(myUsername)/blocked/\(commentAuthor)"
                    Database.database().reference().child(blockPath).setValue(true)
                    
                    var blockListArray = [String]()
                    
                    if let blockList = UserDefaults.standard.object(forKey: "KEY_BLOCKS") as? [String] {
                        blockListArray = blockList
                    }
                    
                    blockListArray.append(commentAuthor)
                    
                    UserDefaults.standard.set(blockListArray, forKey: "KEY_BLOCKS")
                    
                    self.blockedUsernames.add(commentAuthor)
                    self.tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
                    
                    let str = "Blocked \(commentAuthor)."
                    self.showToast(message: str, length: str.count + 2)
                }
                
                popup.addButtons([buttonOne, buttonTwo])
                popup.buttonAlignment = .horizontal
                
                // Present dialog
                self.present(popup, animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "Report", style: .default, handler: { _ in
                // Prepare the popup assets
                let title = "Report this comment?"
                let message = ""
                
                // Create the dialog
                let popup = PopupDialog(title: title, message: message)
                
                // Create buttons
                let buttonOne = DefaultButton(title: "No", action: nil)
                
                // This button will not the dismiss the dialog
                let buttonTwo = DefaultButton(title: "Yes") {
                    let commentReportPath = "reports/c/\(comment.comment_id)/"
                    Database.database().reference().child(commentReportPath).setValue(true)
                    self.showToast(message: "Comment reported.", length: 17)
                }
                
                popup.addButtons([buttonOne, buttonTwo])
                popup.buttonAlignment = .horizontal
                
                // Present dialog
                self.present(popup, animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    func showEditCommentDialog(commentToEdit : VSComment, row : Int) {
        
        // Create a custom view controller
        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let editCommentVC : EditCommentViewController = storyboard.instantiateViewController(withIdentifier: "editCommentVC") as! EditCommentViewController
        let view = editCommentVC.view
        
        if commentToEdit.root != "0" { //the comment has an @prefix
            
            let splitResult = commentToEdit.content.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: false)
            let prefix = String(splitResult[0])
            let content = String(splitResult[1])
            
            print("prefix: \(prefix), content: \(content)")
            
            editCommentVC.setUpWithPrefix(prefix: prefix, commentText: content)
            
        }
        else {
            editCommentVC.setUpWithoutPrefix(commentText: commentToEdit.content)
            
        }
        
        // Create the dialog
        let popup = PopupDialog(viewController: editCommentVC,
                                buttonAlignment: .horizontal,
                                transitionStyle: .bounceDown,
                                tapGestureDismissal: true,
                                panGestureDismissal: false)
        
        // Create first button
        let buttonOne = CancelButton(title: "CANCEL", height: 30) {
            print("cancel")
        }
        
        // Create second button
        let buttonTwo = DefaultButton(title: "OK", height: 30, dismissOnTap: false) {
            if let input = editCommentVC.textInput.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
                if input.count > 0 {
                    var finalInput = ""
                    if let prefix = editCommentVC.prefixLabel.text {
                        finalInput = prefix + " " + input
                    }
                    else {
                        finalInput = input
                    }
                    
                    let commentEditModel = VSCommentEditModel()
                    let commentEditModelDoc = VSCommentEditModel_doc()
                    commentEditModelDoc!.ct = finalInput
                    commentEditModel!.doc = commentEditModelDoc
                    VSVersusAPIClient.default().commenteditPost(body: commentEditModel!, a: "editc", b: commentToEdit.comment_id)
                    self.comments[row].content = finalInput
                    self.nodeMap[commentToEdit.comment_id]?.nodeContent.content = finalInput
                    self.tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
                    self.dismiss(animated: true, completion: nil)
                    self.showToast(message: "Comment edited successfully!", length: 26)
                }
                else {
                    self.showToast(message: "Please enter a comment.", length: 23)
                }
            }
        }
        
        // Add buttons to dialog
        popup.addButtons([buttonOne, buttonTwo])
        
        // Present dialog
        present(popup, animated: true, completion: nil)
    }
    
    
    
}
