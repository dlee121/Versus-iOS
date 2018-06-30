//
//  PasswordViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 6/29/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class PasswordViewController: UIViewController {

    var username : String!
    var birthday : Date!
    @IBOutlet weak var debugLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let formatter = DateFormatter()
        //then again set the date format whhich type of output you need
        formatter.dateFormat = "dd-MMM-yyyy"
        // again convert your date to string
        let myStringafd = formatter.string(from: birthday!)
        
        debugLabel.text = username + myStringafd
        

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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
