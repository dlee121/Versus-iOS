protocol MyCircleDelegator {
    
    func beginUpdatesForSeeMore(row : Int)
    func beginUpdates()
    func endUpdates()
    func endUpdatesForSeeLess(row : Int)
    func replyButtonTapped(row : Int)
    func goToProfile(username : String)
    func overflowTapped(commentID : String, sender: UIButton, rowNumber : Int)
    
}
