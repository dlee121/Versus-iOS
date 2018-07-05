//
//  MCViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 6/29/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import Firebase

class MCViewController: UIViewController {

    @IBOutlet weak var debugLabel: UILabel!
    
    @IBOutlet weak var bdaylabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        /*
        VSVersusAPIClient.default().userHead(a: "uc", b: "cageyogurt").continueWith(block:) {(task: AWSTask) -> Empty? in
            if task.error != nil{
                DispatchQueue.main.async {
                    self.debugLabel.text = "Username available"
                }
            }
            else{
                DispatchQueue.main.async {
                    self.debugLabel.text = "noerr"
                    
                }
            }
            
            return nil
        }
        */
        
        
        
        
 
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logOutTapped(_ sender: UIButton) {
        //remove session data, log out firebase user, then segue back to start screen
        UserDefaults.standard.removeObject(forKey: "KEY_BDAY")
        UserDefaults.standard.removeObject(forKey: "KEY_EMAIL")
        UserDefaults.standard.removeObject(forKey: "KEY_USERNAME")
        UserDefaults.standard.removeObject(forKey: "KEY_PI")
        UserDefaults.standard.removeObject(forKey: "KEY_IS_NATIVE")
        try! Auth.auth().signOut()
        performSegue(withIdentifier: "logOutToStart", sender: self)
    }
    
    @IBAction func apiTestButtonTapped(_ sender: UIButton) {
        bdaylabel.text = UserDefaults.standard.string(forKey: "KEY_USERNAME")
        VSVersusAPIClient.default().postinfoGet(a: "pinf", b: "18f7c832824e4c259d018f60f54b45bb").continueWith(block:) {(task: AWSTask) -> AnyObject? in
            if task.error != nil {
                DispatchQueue.main.async {
                    print(task.error!)
                }
            }
            else {
                DispatchQueue.main.async {
                    self.debugLabel.text = task.result?.rn
                }
            }
            return nil
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
