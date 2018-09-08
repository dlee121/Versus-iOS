protocol MyCircleDelegator {
    
    func beginUpdatesForSeeMore(row : Int)
    func beginUpdates()
    func endUpdates()
    func endUpdatesForSeeLess(row : Int)
    func replyButtonTapped(row : Int)
    
}
