//
//  SignUpViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 9/16/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import FirebaseAuth

class SignUpViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SignUpDelegator {
    
    var array = {"SignUp"}
    var authID : String?
    var authCredential : AuthCredential?
    var screenHeight : CGFloat!
    
    @IBOutlet weak var tableView: UITableView!
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "signUpCell", for: indexPath) as! SignUpTableViewCell
        cell.setCell(isNative: (authID == nil), delegator: self)
        return cell
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        
        screenHeight = UIScreen.main.bounds.height
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(notification:)),
                                               name: NSNotification.Name.UIKeyboardWillHide,
                                               object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        NotificationCenter.default.removeObserver(self)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        tableView.isScrollEnabled = true
        
        if authID == nil || screenHeight < 666 {
            let userInfo: NSDictionary = notification.userInfo! as NSDictionary
            let keyboardInfo = userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue
            let keyboardSize = keyboardInfo.cgRectValue.size
            if keyboardSize.height > tableView.contentInset.bottom {
                let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
                tableView.contentInset = contentInsets
                tableView.scrollIndicatorInsets = contentInsets
                tableView.scrollToRow(at: IndexPath(item: 0, section: 0), at: UITableViewScrollPosition.bottom, animated: true)
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        tableView.isScrollEnabled = false
        
        if authID == nil || screenHeight < 666 {
            tableView.contentInset = .zero
            tableView.scrollIndicatorInsets = .zero
        }
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func signUpButtonTapped(username: String, pw: String?) {
        
        if authID == nil {
            //native signup
            if username != nil && pw != nil {
                let password = pw! //just so I don't fuck around and end up with "Optional("pw")"
                print("username = \(username), password = \(pw)")
                
                
            }
            else {
                showToast(message: "Please check your network.", length: 26)
            }
            
        }
        else {
            //fb or google signup
            if username != nil && pw == nil {
                print("username = \(username)")
                
                
            }
            else {
                showToast(message: "Please check your network.", length: 26)
            }
        }
        
        
    }
    
    func showSUVCToast(text : String) {
        showToast(message: text, length: text.count)
    }
    

}

protocol SignUpDelegator {
    func signUpButtonTapped(username : String, pw : String?)
    func showSUVCToast(text : String)
}




