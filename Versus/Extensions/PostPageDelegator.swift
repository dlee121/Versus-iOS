protocol PostPageDelegator {
    func callSegueFromCell(profileUsername: String)
    func resizePostCardOnVote(red : Bool)
    func commentHearted(commentID : String)
    func commentBrokenhearted(commentID : String)
    func beginUpdatesForSeeMore(row : Int)
    func beginUpdates()
    func endUpdates()
    func endUpdatesForSeeLess(row : Int)
    func replyButtonTapped(replyTarget : VSComment, row : Int)
}
