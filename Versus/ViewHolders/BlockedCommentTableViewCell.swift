//
//  BlockedCommentTableViewCell.swift
//  Versus
//
//  Created by Dongkeun Lee on 10/5/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class BlockedCommentTableViewCell: UITableViewCell {

    
    var delegate : PostPageDelegator!
    var comment : VSComment!
    var rowNumber : Int!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func overflowTapped(_ sender: UIButton) {
        delegate.blockedCardOverflow(comment: comment, sender: sender, row: rowNumber)
    }
    
    

}
