//
//  CreatePostViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 8/15/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class CreatePostViewController: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var question: UITextField!
    @IBOutlet weak var categoryButton: UIButton!
    @IBOutlet weak var redName: UITextField!
    @IBOutlet weak var blueName: UITextField!
    @IBOutlet weak var leftImage: UIButton!
    @IBOutlet weak var rightImage: UIButton!
    @IBOutlet weak var leftOptionalLabel: UILabel!
    @IBOutlet weak var rightOptionalLabel: UILabel!
    
    var prepareCategoryPage : Bool!
    var leftClick = true
    var selectedCategory : String?
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        

        // Do any additional setup after loading the view.
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
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
        if selectedCategory == nil || selectedCategory!.count <= 0 {
            showToast(message: "Please select a category", length: 24)
        }
        else if question.text!.count <= 0 {
            showToast(message: "Please enter a question or topic for this post", length: 40)
        }
        else if redName.text!.count <= 0 || blueName.text!.count <= 0 {
            showMultilineToast(message: "Please enter what you'd like to compare\n(pictures optional)", length: 37, lines: 2)
        }
    }
    
    
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        (tabBarController as! TabBarViewController).createPostBack()
        tabBarController?.tabBar.isHidden = false
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
    
    
    @IBAction func leftImageButtonTapped(_ sender: UIButton) {
        leftClick = true
        
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        }))
        
        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallary()
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        /*If you want work actionsheet on ipad
         then you have to use popoverPresentationController to present the actionsheet,
         otherwise app will crash on iPad */
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            alert.popoverPresentationController?.sourceView = sender
            alert.popoverPresentationController?.sourceRect = sender.bounds
            alert.popoverPresentationController?.permittedArrowDirections = .up
        default:
            break
        }
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func rightImageButtonTapped(_ sender: UIButton) {
        leftClick = false
        
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        }))
        
        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallary()
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        /*If you want work actionsheet on ipad
         then you have to use popoverPresentationController to present the actionsheet,
         otherwise app will crash on iPad */
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            alert.popoverPresentationController?.sourceView = sender
            alert.popoverPresentationController?.sourceRect = sender.bounds
            alert.popoverPresentationController?.permittedArrowDirections = .up
        default:
            break
        }
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func openCamera()
    {
        if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerControllerSourceType.camera))
        {
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
        else
        {
            let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func openGallary()
    {
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        imagePicker.allowsEditing = true
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as?  UIImage {
            if leftClick {
                leftImage.setImage(image, for: .normal)
            }
            else {
                rightImage.setImage(image, for: .normal)
            }
            
        }
        else {
            showToast(message: "Couldn't load the image", length: 23)
        }
        
        self.dismiss(animated: true, completion: nil)
        leftOptionalLabel.isHidden = true
        rightOptionalLabel.isHidden = true
    }
    
    
    
    
}
