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
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func endEditing() {
        view.endEditing(true)
    }
}

extension EmailSetupVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        endEditing()
        return true
    }
}
