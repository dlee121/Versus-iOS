//
//  RatingViewController.swift
//  PopupDialog
//
//  Created by Martin Wildfeuer on 11.07.16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

class EmailSetupVC: UIViewController {
    
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var asswordpay: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textField.delegate = self
        asswordpay.delegate = self
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(endEditing)))
        
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "eye.png"), for: .normal)
        //button.imageEdgeInsets = UIEdgeInsetsMake(0, -16, 0, 0)
        button.frame = CGRect(x: CGFloat(asswordpay.frame.size.width - 25), y: CGFloat(5), width: CGFloat(25), height: CGFloat(25))
        button.addTarget(self, action: #selector(self.pwtoggle), for: .touchUpInside)
        asswordpay.rightView = button
        asswordpay.rightViewMode = .always
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func endEditing() {
        view.endEditing(true)
    }
    
    @objc
    func pwtoggle(_ sender: Any) {
        asswordpay.isSecureTextEntry = !asswordpay.isSecureTextEntry
        if let existingText = asswordpay.text, asswordpay.isSecureTextEntry {
            /* When toggling to secure text, all text will be purged if the user
             * continues typing unless we intervene. This is prevented by first
             * deleting the existing text and then recovering the original text. */
            asswordpay.deleteBackward()
            
            if let textRange = asswordpay.textRange(from: asswordpay.beginningOfDocument, to: asswordpay.endOfDocument) {
                asswordpay.replace(textRange, withText: existingText)
            }
        }
        else if let textRange = asswordpay.textRange(from: asswordpay.beginningOfDocument, to: asswordpay.endOfDocument) {
            //we still do this to get rid of extra spacing that happens when toggling secure text
            asswordpay.replace(textRange, withText: asswordpay.text!)
        }
        
    }
}

extension EmailSetupVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        endEditing()
        return true
    }
}
