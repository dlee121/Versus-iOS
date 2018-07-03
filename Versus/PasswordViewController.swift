//
//  PasswordViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 6/29/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import Firebase

class PasswordViewController: UIViewController {

    var username : String!
    var birthday : Date!
    @IBOutlet weak var debugLabel: UILabel!
    @IBOutlet weak var passwordIn: UITextField!
    var confirmedPW : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
        let formatter = DateFormatter()
        formatter.dateFormat = "M-d-yyyy"
        let myStringafd = formatter.string(from: birthday!)
        */
        
        debugLabel.text = ""
        

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func backTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "backToUsername", sender: self)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == "backToUsername"{
                guard let usernameVC = segue.destination as? UsernameViewController else {return}
                usernameVC.birthday = birthday
                print(username)
                usernameVC.confirmedInput = username
            }
        }
    }
 
    
    @IBAction func textChangeListener(_ sender: UITextField) {
        confirmedPW = nil
        if let input = passwordIn.text{
            if input.count > 0{
                if input.count >= 6{
                    if input.prefix(1) == " "{
                        debugLabel.text = "Password cannot start with blank space"
                        debugLabel.textColor = UIColor(named: "noticeRed")
                    }
                    else if input.suffix(1) == " "{
                        debugLabel.text = "Password cannot end with blank space"
                        debugLabel.textColor = UIColor(named: "noticeRed")
                    }
                    else{
                        passwordStrengthCheck(pw: input)
                        confirmedPW = input
                    }
                }
                else{
                    debugLabel.text = "Must be at least 6 characters"
                    debugLabel.textColor = UIColor(named: "noticeRed")
                }
            }
            else{
                debugLabel.text = ""
            }
        }
    }
    
    func passwordStrengthCheck(pw: String) {
        var strength = 0
        
        if(pw.count >= 4){
            strength += 1
        }
        if(pw.count >= 6){
            strength += 1
        }
        if(pw.lowercased() != pw){
            strength += 1
        }
        var digitCount = 0
        for i in 0...pw.count-1 {
            if "0"..."9" ~= String(pw[pw.index(pw.startIndex, offsetBy: i)]) {
                digitCount += 1
            }
        }
        if(1...pw.count ~= digitCount){
            strength += 1
        }
        
        switch (strength){
            case 0:
                debugLabel.textColor = UIColor(named: "noticeRed")
                debugLabel.text = "Password strength: weak"
            case 1:
                debugLabel.textColor = UIColor(named: "noticeRed")
                debugLabel.text = "Password strength: weak"
            case 2:
                debugLabel.text = "Password strength: medium"
                debugLabel.textColor = UIColor(named: "noticeYellow")
            case 3:
                debugLabel.text = "Password strength: good"
                debugLabel.textColor = UIColor(named: "noticeGreen")
            case 4:
                debugLabel.text = "Password strength: strong"
                debugLabel.textColor = UIColor(named: "noticeGreen")
            default:
                debugLabel.text = "Password strength: medium"
                debugLabel.textColor = UIColor(named: "noticeYellow")
        }
    }
    
    
    @IBAction func nextTapped(_ sender: Any) {
        //sign up the user using firebase
        if birthday != nil && username != nil && confirmedPW != nil {
            Auth.auth().createUser(withEmail: username+"@versusbcd.com", password: confirmedPW) { (authResult, error) in
                // ...
                if let user = authResult?.user {
                    print("signed up as " + user.email!)
                    user.getIDToken(){ (tokenResult, error) in
                        if error != nil {
                            // Handle error
                            return;
                        }
                        //set AWS credentials with the retrieved token
                        
                        
                        
                    }
                    
                    
                    
                    
                    self.performSegue(withIdentifier: "signUpToMain", sender: self)
                    
                }
                else{
                    self.showToast(message: "Something went wrong, please try again.", length: 30)
                }
            }
        }
        else {
            showToast(message: "Something went wrong, please try again.", length: 26)
        }
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    

}
