//
//  BlockedUserTableViewCell.swift
//  Versus
//
//  Created by Dongkeun Lee on 10/4/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class BlockedUserTableViewCell: UITableViewCell {

    @IBOutlet weak var username: UILabel!
    var rowNumber : Int!
    var delegate : BlockedUsersDelegator!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    
    @IBAction func unblockButtonTapped(_ sender: UIButton) {
        delegate.unblockUser(username: username.text!, rowNumber: rowNumber)
        
    }
    
}
