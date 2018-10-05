//
//  GDPRFinalViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 10/5/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class GDPRFinalViewController: UIViewController {
    @IBOutlet weak var textLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func startButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "adConsentToMain", sender: self)
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
