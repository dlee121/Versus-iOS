//
//  CreatePostViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 8/15/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import AWSS3

class CreatePostViewController: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var question: UITextField!
    @IBOutlet weak var categoryButton: UIButton!
    @IBOutlet weak var redName: UITextField!
    @IBOutlet weak var blueName: UITextField!
    @IBOutlet weak var leftImage: UIButton!
    @IBOutlet weak var rightImage: UIButton!
    @IBOutlet weak var leftOptionalLabel: UILabel!
    @IBOutlet weak var rightOptionalLabel: UILabel!
    
    @IBOutlet weak var leftImageCancelButton: UIButton!
    
    @IBOutlet weak var rightImageCancelButton: UIButton!
    var prepareCategoryPage: Bool!
    var leftImageSet, rightImageSet : NSNumber!
    var leftClick = true
    var selectedCategory : String?
    var selectedCategoryNum : NSNumber?
    
    let imagePicker = UIImagePickerController()
    let DEFAULT : NSNumber = 0
    let S3 : NSNumber = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        leftImage.imageView!.contentMode = .scaleAspectFill
        rightImage.imageView!.contentMode = .scaleAspectFill
        leftImageSet = DEFAULT
        rightImageSet = DEFAULT
        

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
        else {
            
            let newPost = PostObject(q: question.text!, rn: redName.text!, bn: blueName.text!, a: UserDefaults.standard.string(forKey: "KEY_USERNAME")!, c: selectedCategoryNum!, ri: leftImageSet, bi: rightImageSet)
            
            if leftImageSet == S3 {
                uploadImages(postID: newPost.post_id)
            }
            if rightImageSet == S3 {
                uploadImages(postID: newPost.post_id)
            }
            
            VSVersusAPIClient.default().postputPost(body: newPost.getPostPutModel(), c: newPost.post_id, a: "postput", b: newPost.author.lowercased()).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                if task.error != nil {
                    DispatchQueue.main.async {
                        print(task.error!)
                    }
                }
                else {
                    //Post creation successful. Navigate to the corresponding post page.
                    print("ayyyyyyyy postID: \(newPost.post_id)")
                    
                }
                return nil
            }
            
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
        leftImageSet = DEFAULT
        rightImageSet = DEFAULT
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
        if let image = info[UIImagePickerControllerEditedImage] as?  UIImage {
            
            if leftClick {
                leftImage.backgroundColor = .black
                leftImage.setImage(image, for: .normal)
                leftOptionalLabel.isHidden = true
                leftImageCancelButton.isHidden = false
                leftImageSet = S3
            }
            else {
                rightImage.backgroundColor = .black
                rightImage.setImage(image, for: .normal)
                rightOptionalLabel.isHidden = true
                rightImageCancelButton.isHidden = false
                rightImageSet = S3
            }
            
        }
        else if let image = info[UIImagePickerControllerOriginalImage] as?  UIImage {
            
            if leftClick {
                leftImage.backgroundColor = .black
                leftImage.setImage(image, for: .normal)
                leftOptionalLabel.isHidden = true
                leftImageCancelButton.isHidden = false
                leftImageSet = S3
            }
            else {
                rightImage.backgroundColor = .black
                rightImage.setImage(image, for: .normal)
                rightOptionalLabel.isHidden = true
                rightImageCancelButton.isHidden = false
                rightImageSet = S3
            }
            
        }
        else {
            showToast(message: "Couldn't load the image", length: 23)
        }
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    
    @IBAction func leftImageCancelTapped(_ sender: UIButton) {
        leftImageSet = DEFAULT
        leftImage.backgroundColor = .white
        leftImage.setImage(#imageLiteral(resourceName: "plus_blue"), for: .normal)
        leftImageCancelButton.isHidden = true
        leftOptionalLabel.isHidden = false
    }
    
    @IBAction func rightImageCancelTapped(_ sender: UIButton) {
        rightImageSet = DEFAULT
        rightImage.backgroundColor = .white
        rightImage.setImage(#imageLiteral(resourceName: "plus_blue"), for: .normal)
        rightImageCancelButton.isHidden = true
        rightOptionalLabel.isHidden = false
    }
    
    func uploadImages(postID : String) {
        if leftImageSet == S3 {
            let imageKey = postID+"-left.jpeg"
            let image = leftImage.currentImage!
            let fileManager = FileManager.default
            let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(imageKey)
            let imageData = UIImageJPEGRepresentation(image, 0.5)
            fileManager.createFile(atPath: path as String, contents: imageData, attributes: nil)
            
            let fileUrl = NSURL(fileURLWithPath: path)
            let uploadRequest = AWSS3TransferManagerUploadRequest()
            uploadRequest?.bucket = "versus.pictures"
            uploadRequest?.key = imageKey
            uploadRequest?.contentType = "image/jpeg"
            uploadRequest?.body = fileUrl as URL
            uploadRequest?.serverSideEncryption = AWSS3ServerSideEncryption.awsKms
            /*
            uploadRequest?.uploadProgress = { (bytesSent, totalBytesSent, totalBytesExpectedToSend) -> Void in
                DispatchQueue.main.async(execute: {
                    self.amountUploaded = totalBytesSent // To show the updating data status in label.
                    self.fileSize = totalBytesExpectedToSend
                })
            }
            */
            
            let transferManager = AWSS3TransferManager.default()
            transferManager.upload(uploadRequest!).continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask<AnyObject>) -> Any? in
                
                if let error = task.error as? NSError {
                    if error.domain == AWSS3TransferManagerErrorDomain, let code = AWSS3TransferManagerErrorType(rawValue: error.code) {
                        switch code {
                        case .cancelled, .paused:
                            break
                        default:
                            print("Error uploading: \(uploadRequest!.key) Error: \(error)")
                        }
                    } else {
                        print("Error uploading: \(uploadRequest!.key) Error: \(error)")
                    }
                    return nil
                }
                else {
                    //for now we don't handle additional code for image upload success
                }
                
                return nil
            })
        }
        
        
        if rightImageSet == S3 {
            let imageKey = postID+"-right.jpeg"
            let image = rightImage.currentImage!
            let fileManager = FileManager.default
            let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(imageKey)
            let imageData = UIImageJPEGRepresentation(image, 0.5)
            fileManager.createFile(atPath: path as String, contents: imageData, attributes: nil)
            
            let fileUrl = NSURL(fileURLWithPath: path)
            let uploadRequest = AWSS3TransferManagerUploadRequest()
            uploadRequest?.bucket = "versus.pictures"
            uploadRequest?.key = imageKey
            uploadRequest?.contentType = "image/jpeg"
            uploadRequest?.body = fileUrl as URL
            uploadRequest?.serverSideEncryption = AWSS3ServerSideEncryption.awsKms
            /*
             uploadRequest?.uploadProgress = { (bytesSent, totalBytesSent, totalBytesExpectedToSend) -> Void in
             DispatchQueue.main.async(execute: {
             self.amountUploaded = totalBytesSent // To show the updating data status in label.
             self.fileSize = totalBytesExpectedToSend
             })
             }
             */
            
            let transferManager = AWSS3TransferManager.default()
            transferManager.upload(uploadRequest!).continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask<AnyObject>) -> Any? in
                
                if let error = task.error as? NSError {
                    if error.domain == AWSS3TransferManagerErrorDomain, let code = AWSS3TransferManagerErrorType(rawValue: error.code) {
                        switch code {
                        case .cancelled, .paused:
                            break
                        default:
                            print("Error uploading: \(uploadRequest!.key) Error: \(error)")
                        }
                    } else {
                        print("Error uploading: \(uploadRequest!.key) Error: \(error)")
                    }
                    return nil
                }
                else {
                    //for now we don't handle additional code for image upload success
                }
                
                return nil
            })
        }
        
        
    }
    
    
    
    
    
    
}
