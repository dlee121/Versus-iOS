//
//  SignUpTableViewCell.swift
//  Versus
//
//  Created by Dongkeun Lee on 9/17/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class SignUpTableViewCell: UITableViewCell {

    @IBOutlet weak var usernameIn: UITextField!
    @IBOutlet weak var passwordIn: UITextField!
    @IBOutlet weak var legalText: UILabel!
    @IBOutlet weak var createAccountLabel: UIButton!
    
    @IBOutlet weak var passwordInHeight: NSLayoutConstraint!
    @IBOutlet weak var passwordLabelHeight: NSLayoutConstraint!
    
    func setCell(isNative : Bool) {
        /*
        if isNative {
            passwordInHeight.constant = 38
            passwordLabelHeight.constant = 17
        }
        else {
            passwordInHeight.constant = 0
            passwordLabelHeight.constant = 0
        }
        */
        passwordInHeight.constant = 0
        passwordLabelHeight.constant = 0
        
        
    }
    
    
    
    
    
    
    
    
    @IBAction func createAccountButtonTapped(_ sender: UIButton) {
        
        
    }
    
}
