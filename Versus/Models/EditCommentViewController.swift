//
//  EditCommentViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 9/26/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class EditCommentViewController: UIViewController {

    
    @IBOutlet weak var prefixLabel: UILabel!
    @IBOutlet weak var prefixHeight: NSLayoutConstraint!
    @IBOutlet weak var textInput: UITextView!
    
    var commentPrefix : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let color = UIColor(red: 186/255, green: 186/255, blue: 186/255, alpha: 1.0).cgColor
        textInput.layer.borderColor = color
        textInput.layer.borderWidth = 0.5
        textInput.layer.cornerRadius = 5
        
        textInput.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUpWithPrefix(prefix : String, commentText : String) {
        commentPrefix = prefix
        prefixLabel.text = prefix
        prefixHeight.constant = 21
        
        textInput.text = commentText
        
    }
    
    func setUpWithoutPrefix(commentText : String) {
        commentPrefix = nil
        prefixLabel.text = ""
        prefixHeight.constant = 0
        
        textInput.text = commentText
        
        
    }
    
    
    
    
    
    
}
