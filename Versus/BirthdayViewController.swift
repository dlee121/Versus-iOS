//
//  BirthdayViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 6/29/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class BirthdayViewController: UIViewController {
    @IBOutlet weak var bdayInput: UIDatePicker!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    // Age of 16.
    let MINIMUM_AGE: Date = Calendar.current.date(byAdding: .year, value: -16, to: Date())!
    let PICKER_CEILING: Date = Calendar.current.date(byAdding: .year, value: -100, to: Date())!;
    var dateInput: Date!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        dateInput = bdayInput.date
        bdayInput.minimumDate = PICKER_CEILING
        bdayInput.maximumDate = MINIMUM_AGE
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "backToStartScreen", sender: self)
    }
    
    @IBAction func nextButtonTapped(_ sender: UIButton) {
        let isValidAge = validateAge(birthDate: bdayInput.date)
        
        if isValidAge {
            performSegue(withIdentifier: "goToUsername", sender: self)
        } else {
            showToast(message: "You must be at least 16 years old", length: 33)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let usernameVC = segue.destination as? UsernameViewController else {return}
        usernameVC.birthday = bdayInput.date
    }
    
    func validateAge(birthDate: Date) -> Bool {
        var isValid: Bool = true;
        
        if birthDate >= MINIMUM_AGE {
            isValid = false;
        }
        
        return isValid;
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
