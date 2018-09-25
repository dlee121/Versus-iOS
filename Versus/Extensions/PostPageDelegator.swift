protocol PostPageDelegator {
    func goToProfile(profileUsername: String)
    func resizePostCardOnVote(red : Bool)
    func commentHearted(commentID : String)
    func commentBrokenhearted(commentID : String)
    func beginUpdatesForSeeMore(row : Int)
    func beginUpdates()
    func endUpdates()
    func endUpdatesForSeeLess(row : Int)
    func replyButtonTapped(replyTarget : VSComment, cell : CommentCardTableViewCell)
    func viewMoreRepliesTapped(topCardComment : VSComment)
    func presentSortMenu(sortButtonLabel : UILabel)
    func commentCardOverflow(comment : VSComment, sender : UIButton)
}
