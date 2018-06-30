//
//  UsernameViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 6/29/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class UsernameViewController: UIViewController {
    
    var birthday: Date!
    @IBOutlet weak var debugLabel: UILabel!
    let client = VSVersusAPIClient.default()
    var usernameVersion = 0
    var confirmedInput : String! //username input that is confirmed to be available. Use this for signup
    
    @IBOutlet weak var usernameIn: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func textChangeListener(_ sender: UITextField) {
        usernameVersion += 1
        let thisVersion = usernameVersion
        let input = usernameIn.text
        self.debugLabel.text = "Checking username..."
        client.userHead(a: "uc", b: usernameIn.text?.lowercased()).continueWith(block:) {(task: AWSTask) -> Empty? in
            if task.error != nil{
                DispatchQueue.main.async {
                    if(thisVersion == self.usernameVersion){
                        self.debugLabel.text = "Username available"
                        self.confirmedInput = input!
                    }
                }
            }
            else{
                DispatchQueue.main.async {
                    if(thisVersion == self.usernameVersion){
                        self.debugLabel.text = self.usernameIn.text! + " is already taken!"
                    }
                }
            }
            
            return nil
        }
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
