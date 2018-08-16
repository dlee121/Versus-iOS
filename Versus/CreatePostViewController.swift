//
//  CreatePostViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 8/15/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class CreatePostViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var question: UITextField!
    @IBOutlet weak var categoryButton: UIButton!
    @IBOutlet weak var redName: UITextField!
    @IBOutlet weak var blueName: UITextField!
    @IBOutlet weak var leftImage: UIButton!
    @IBOutlet weak var rightImage: UIButton!
    @IBOutlet weak var leftOptionalLabel: UILabel!
    @IBOutlet weak var rightOptionalLabel: UILabel!
    
    var prepareCategoryPage : Bool!
    var selectedCategory : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        //self.tabBarController?.tabBar.isHidden = false
        question.text = ""
        categoryButton.setTitle("Select a Category", for: .normal)
        redName.text = ""
        blueName.text = ""
        leftImage.setImage(#imageLiteral(resourceName: "plus_blue"), for: .normal)
        rightImage.setImage(#imageLiteral(resourceName: "plus_blue"), for: .normal)
        leftOptionalLabel.isHidden = false
        rightOptionalLabel.isHidden = false
        selectedCategory = ""
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
        switch textField.returnKeyType {
        case UIReturnKeyType.next:
            // Try to find next responder
            if let nextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField {
                nextField.becomeFirstResponder()
            } else {
                // Not found, so remove keyboard.
                textField.resignFirstResponder()
            }
            
        default:
            textField.resignFirstResponder()
        }
        
        return true
    }
    
    
    @IBAction func categoryButtonTapped(_ sender: UIButton) {
        
        prepareCategoryPage = true
        performSegue(withIdentifier: "presentCategorySelector", sender: self)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if prepareCategoryPage {
            guard let categoriesVC = segue.destination as? CategoryFilterViewController else {return}
            categoriesVC.tab2Or3OrCP = 4
            categoriesVC.originVC = self
        }
        else { //this is for segue to PostPage. Be sure to set prepareCategoryFilter = false to access this block
            
            //TODO: handle preparation for post item click here
        }
    }
    
    
    @IBAction func postButtonTapped(_ sender: UIButton) {
        
        
        
    }
    
    
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        (tabBarController as! TabBarViewController).createPostBack()
        tabBarController?.tabBar.isHidden = false
    }
    
    
    
}
