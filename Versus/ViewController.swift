//
//  ViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 6/27/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController {
    @IBOutlet weak var usernameIn: UITextField!
    @IBOutlet weak var passwordIn: UITextField!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    var handle: AuthStateDidChangeListenerHandle!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "eye.png"), for: .normal)
        //button.imageEdgeInsets = UIEdgeInsetsMake(0, -16, 0, 0)
        button.frame = CGRect(x: CGFloat(passwordIn.frame.size.width - 25), y: CGFloat(5), width: CGFloat(25), height: CGFloat(25))
        button.addTarget(self, action: #selector(self.pwtoggle), for: .touchUpInside)
        passwordIn.rightView = button
        passwordIn.rightViewMode = .always
    }
    
    override func viewWillAppear(_ animated: Bool){
        super.viewWillAppear(animated)
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            // ...
            if user == nil{
                //not currently signed in
                print("not currently signed in")
            }
            else{
                //currently signed in
                print("signed in as " + user!.email!)
            }
        }
        
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Auth.auth().removeStateDidChangeListener(handle)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func logInButtonTapped(_ sender: UIButton) {
        //log in user with Firebase
        
        if let username = usernameIn.text {
            if let pw = passwordIn.text{
                if username.count == 0{
                    showToast(message: "Please enter your username")
                }
                else if pw.count == 0{
                    showToast(message: "Please enter your password")
                }
                else{
                    Auth.auth().signIn(withEmail: username+"@versusbcd.com", password: pw) { (result, error) in
                        // ...
                        if let email = result?.user.email {
                            print("signed in as " + email)
                        }
                        else{
                            self.showToast(message: "incorrect username or password")
                        }
                    }
                }
            }
            else{
                showToast(message: "Please enter your password")
            }
        }
        else {
            showToast(message: "Please enter your username")
            
        }
        
        
    }
    
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        //sign up user with Firebase
        
        //try? Auth.auth().signOut()
        //print("signed out")
        
        performSegue(withIdentifier: "goToSignUp", sender: self)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //dismiss keyboard when the view is tapped on
        usernameIn.resignFirstResponder()
        passwordIn.resignFirstResponder()
    }
    
    @IBAction func pwtoggle(_ sender: Any) {
        passwordIn.isSecureTextEntry = !passwordIn.isSecureTextEntry
        if let existingText = passwordIn.text, passwordIn.isSecureTextEntry {
            /* When toggling to secure text, all text will be purged if the user
             * continues typing unless we intervene. This is prevented by first
             * deleting the existing text and then recovering the original text. */
            passwordIn.deleteBackward()
            
            if let textRange = passwordIn.textRange(from: passwordIn.beginningOfDocument, to: passwordIn.endOfDocument) {
                passwordIn.replace(textRange, withText: existingText)
            }
        }
        else if let textRange = passwordIn.textRange(from: passwordIn.beginningOfDocument, to: passwordIn.endOfDocument) {
            //we still do this to get rid of extra spacing that happens when toggling secure text
            passwordIn.replace(textRange, withText: passwordIn.text!)
        }
        
    }
    

}

