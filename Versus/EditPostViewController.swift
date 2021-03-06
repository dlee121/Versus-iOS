//
//  CreatePostViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 8/15/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import AWSS3
import Nuke
import FirebaseStorage
import FirebaseDatabase

class EditPostViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    
    
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var postingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var initialIVLeft: UIImageView!
    @IBOutlet weak var initialIVRight: UIImageView!
    
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var rednameLabel: UILabel!
    @IBOutlet weak var bluenameLabel: UILabel!
    
    @IBOutlet weak var categoryButton: UIButton!
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
    var createdPost : PostObject?
    
    let imagePicker = UIImagePickerController()
    let DEFAULT : NSNumber = 0
    let S3 : NSNumber = 1
    
    var editTargetPost : PostObject!
    
    var leftImageIn, rightImageIn : UIImage?
    var virginPage = true
    
    var group : DispatchGroup!
    var sourceVC : RootPageViewController!
    
    var ref: DatabaseReference!
    var storageRef : StorageReference!
    var refHandleLeft, refHandleRight : DatabaseHandle!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        group = DispatchGroup()
        navigationItem.title = "Edit Post"
        
        imagePicker.delegate = self
        leftImage.imageView!.contentMode = .scaleAspectFill
        rightImage.imageView!.contentMode = .scaleAspectFill
        leftImageSet = DEFAULT
        rightImageSet = DEFAULT
        
        ref = Database.database().reference()
        storageRef = Storage.storage().reference()
        
        // Do any additional setup after loading the view.
        
        
    }
    
    func setEditPage(postToEdit : PostObject, redImg : UIImage?, blueImg : UIImage?, rootVC : RootPageViewController) {
        virginPage = true
        sourceVC = rootVC
        editTargetPost = postToEdit
        questionLabel.text = postToEdit.question
        rednameLabel.text = postToEdit.redname
        bluenameLabel.text = postToEdit.blackname
        selectedCategory = getCategoryName(categoryInt: postToEdit.category.intValue)
        categoryButton.setTitle(selectedCategory, for: .normal)
        selectedCategoryNum = postToEdit.category
        
        if postToEdit.redimg.intValue % 10 == 1 {
            getPostImage(postID: postToEdit.post_id, lORr: 0, editVersion: postToEdit.redimg.intValue / 10)
            leftOptionalLabel.isHidden = true
            leftImageCancelButton.isHidden = false
            leftImageSet = S3
        }
        if postToEdit.blackimg.intValue % 10 == 1 {
            getPostImage(postID: postToEdit.post_id, lORr: 1, editVersion: postToEdit.blackimg.intValue / 10)
            rightOptionalLabel.isHidden = true
            rightImageCancelButton.isHidden = false
            rightImageSet = S3
        }
        
        
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func categoryButtonTapped(_ sender: UIButton) {
        prepareCategoryPage = true
        performSegue(withIdentifier: "editPostToCategories", sender: self)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let categoriesVC = segue.destination as? CategoryFilterViewController else {return}
        categoriesVC.sourceType = 5
        categoriesVC.originVC = self
    }
    
    @IBAction func closeButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func leftImageButtonTapped(_ sender: UIButton) {
        leftClick = true
        
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = sender.bounds
        
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
        
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = sender.bounds
        
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
    
    @IBAction func submitEdit(_ sender: UIButton) {
        if !virginPage {
            postingIndicator.startAnimating()
            postButton.isHidden = true
            var postEdited = false
            if editTargetPost.category != selectedCategoryNum {
                print("cat changed")
                editTargetPost.category = selectedCategoryNum!
                
                postEdited = true
            }
            
            if (editTargetPost.redimg.intValue % 10 == 1 && initialIVLeft.image == nil) || (editTargetPost.redimg.intValue % 10 == 0 && leftOptionalLabel.isHidden) {
                
                if editTargetPost.redimg.intValue % 10 == 1 {
                    let s3 = AWSS3.default()
                    let deleteObjectRequest = AWSS3DeleteObjectRequest()
                    deleteObjectRequest!.bucket = "versus.pictures"
                    
                    let oldEditVersion = editTargetPost.redimg.intValue / 10
                    
                    if oldEditVersion > 0 {
                        deleteObjectRequest!.key = "\(editTargetPost.post_id)-left\(oldEditVersion).jpeg"
                    }
                    else {
                        deleteObjectRequest!.key = "\(editTargetPost.post_id)-left.jpeg"
                    }
                    
                    s3.deleteObject(deleteObjectRequest!)
                }
                
                if leftOptionalLabel.isHidden { //new image is set
                    
                    editTargetPost.redimg = NSNumber(value: (editTargetPost.redimg.intValue / 10 + 1) * 10 + 1)
                    
                    //upload new image
                    group.enter()
                    uploadImage(imageKey: editTargetPost.post_id+"-left\(editTargetPost.redimg.intValue / 10).jpeg", rawImage: leftImage.currentImage!)
                    
                }
                else { //image is deleted
                    editTargetPost.redimg = NSNumber(value: 0)
                }
                
                
                
                postEdited = true
            }
            
            if (editTargetPost.blackimg.intValue % 10 == 1 && initialIVRight.image == nil) || (editTargetPost.blackimg.intValue % 10 == 0 && rightOptionalLabel.isHidden) {
                
                if editTargetPost.blackimg.intValue % 10 == 1 {
                    let s3 = AWSS3.default()
                    let deleteObjectRequest = AWSS3DeleteObjectRequest()
                    deleteObjectRequest!.bucket = "versus.pictures"
                    
                    let oldEditVersion = editTargetPost.blackimg.intValue / 10
                    
                    if oldEditVersion > 0 {
                        deleteObjectRequest!.key = "\(editTargetPost.post_id)-right\(oldEditVersion).jpeg"
                    }
                    else {
                        deleteObjectRequest!.key = "\(editTargetPost.post_id)-right.jpeg"
                    }
                    
                    s3.deleteObject(deleteObjectRequest!)
                }
                
                
                if rightOptionalLabel.isHidden { //new image is set
                    
                    editTargetPost.blackimg = NSNumber(value: (editTargetPost.blackimg.intValue / 10 + 1) * 10 + 1)
                    
                    //upload new image
                    group.enter()
                    uploadImage(imageKey: editTargetPost.post_id+"-right\(editTargetPost.blackimg.intValue / 10).jpeg", rawImage: rightImage.currentImage!)
                    
                }
                else { //image is deleted
                    editTargetPost.blackimg = NSNumber(value: 0)
                }
                
                postEdited = true
            }
            
            if postEdited {
                var postEditModel = VSPostEditModel()
                var postEditModelDoc = VSPostEditModel_doc()
                postEditModelDoc!.bi = editTargetPost.blackimg
                postEditModelDoc!.c = editTargetPost.category
                postEditModelDoc!.ri = editTargetPost.redimg
                postEditModel!.doc = postEditModelDoc
                
                group.enter()
                VSVersusAPIClient.default().posteditPost(body: postEditModel!, a: "editp", b: editTargetPost.post_id).continueWith(block:) {(task: AWSTask) -> AnyObject? in
                    if task.error != nil {
                        DispatchQueue.main.async {
                            print(task.error!)
                        }
                    }
                    
                    self.group.leave()
                    
                    return nil
                }
                
                group.notify(queue: .main) {
                    DispatchQueue.main.async {
                        self.sourceVC.currentPost = self.editTargetPost
                        self.sourceVC.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
            else {
                dismiss(animated: true, completion: nil)
            }
        }
        else {
            dismiss(animated: true, completion: nil)
        }
        
        
        
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
        virginPage = false
        if let image = info[UIImagePickerControllerEditedImage] as?  UIImage {
            
            if leftClick {
                initialIVLeft.image = nil
                leftImage.backgroundColor = .black
                leftImage.setImage(image, for: .normal)
                leftOptionalLabel.isHidden = true
                leftImageCancelButton.isHidden = false
                leftImageSet = S3
            }
            else {
                initialIVRight.image = nil
                rightImage.backgroundColor = .black
                rightImage.setImage(image, for: .normal)
                rightOptionalLabel.isHidden = true
                rightImageCancelButton.isHidden = false
                rightImageSet = S3
            }
            
        }
        else if let image = info[UIImagePickerControllerOriginalImage] as?  UIImage {
            
            if leftClick {
                initialIVLeft.image = nil
                leftImage.backgroundColor = .black
                leftImage.setImage(image, for: .normal)
                leftOptionalLabel.isHidden = true
                leftImageCancelButton.isHidden = false
                leftImageSet = S3
            }
            else {
                initialIVRight.image = nil
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
        virginPage = false
        leftImageSet = DEFAULT
        initialIVLeft.image = nil
        leftImage.backgroundColor = .white
        leftImage.setImage(#imageLiteral(resourceName: "plus_blue"), for: .normal)
        leftImageCancelButton.isHidden = true
        leftOptionalLabel.isHidden = false
    }
    
    @IBAction func rightImageCancelTapped(_ sender: UIButton) {
        virginPage = false
        rightImageSet = DEFAULT
        initialIVRight.image = nil
        rightImage.backgroundColor = .white
        rightImage.setImage(#imageLiteral(resourceName: "plus_blue"), for: .normal)
        rightImageCancelButton.isHidden = true
        rightOptionalLabel.isHidden = false
    }
    
    func uploadImage(imageKey : String, rawImage : UIImage) {
        let image : UIImage!
        if rawImage.size.width >= rawImage.size.height {
            image = rawImage.resized(toWidth: 304)
        }
        else {
            image = rawImage.resized(toHeight: 304)
        }
        
        let currentUsername = UserDefaults.standard.string(forKey: "KEY_USERNAME")!
        
        let data : Data = UIImageJPEGRepresentation(rawImage, 0.8)!
        let requestID = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let filePath = "profile/\(currentUsername)/\(requestID).jpg"
        let uploadRef = storageRef.child(filePath)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        uploadRef.putData(data, metadata: metadata) { (metadata, error) in
            if let error = error {
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    self.showToast(message: "Please check your network connection.", length: 37)
                }
                
            }else{
                //attach a listener that listens for image check results and calls executeImageUpload if image is good, otherwise returns with a warning
                
                self.refHandleLeft = self.ref.child("gvresults/\(currentUsername)/\(requestID)").observe(DataEventType.value, with: { (snapshot) in
                    let result = snapshot.value as? String
                    if result != nil {
                        self.ref.child("gvresults/\(currentUsername)/\(requestID)").removeObserver(withHandle: self.refHandleLeft)
                        //fields[0] = Adult, fields[1] = Medical, fields[2] = Violence
                        let fields = result!.split(separator: ",")
                        let imageIsSafe = (fields[0] == "VERY_UNLIKELY" || fields[0] == "UNLIKELY")
                            && (fields[1] == "VERY_UNLIKELY" || fields[1] == "UNLIKELY")
                            && (fields[2] == "VERY_UNLIKELY" || fields[2] == "UNLIKELY")
                        
                        if imageIsSafe {
                            self.executeImageUpload(imageKey: imageKey, image: image)
                        }
                        else {
                            DispatchQueue.main.async {
                                self.showToast(message: "Inappropriate image detected.", length: 29)
                                self.group.leave()
                            }
                        }
                    }
                })
            }
        }
        
        
        
    }
    
    func executeImageUpload(imageKey : String, image : UIImage) {
        
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
                self.group.leave()
            }
            
            return nil
        })
        
        
    }
    
    
    
    func getCategoryName(categoryInt : Int) -> String{
        switch categoryInt {
        case 0:
            return " Automobiles  "
        case 1:
            return " Cartoon/Anime/Fiction  "
        case 2:
            return " Celebrity/Gossip  "
        case 3:
            return " Culture  "
        case 4:
            return " Education  "
        case 5:
            return " Electronics  "
        case 6:
            return " Fashion  "
        case 7:
            return " Finance  "
        case 8:
            return " Food/Restaurant  "
        case 9:
            return " Game/Entertainment  "
        case 10:
            return " Morality/Ethics/Law  "
        case 11:
            return " Movies/TV  "
        case 12:
            return " Music/Artists  "
        case 13:
            return " Politics  "
        case 14:
            return " Random  "
        case 15:
            return " Religion  "
        case 16:
            return " Science  "
        case 17:
            return " Social Issues  "
        case 18:
            return " Sports  "
        case 19:
            return " Technology  "
        case 20:
            return " Weapons  "
        default:
            return " Random  "
        }
        
    }
    
    func getPostImage(postID : String, lORr : Int, editVersion : Int){
        let request = AWSS3GetPreSignedURLRequest()
        request.expires = Date().addingTimeInterval(86400)
        request.bucket = "versus.pictures"
        request.httpMethod = .GET
        
        if lORr == 0 { //left
            if editVersion == 0 {
                request.key = postID + "-left.jpeg"
            }
            else{
                request.key = postID + "-left\(editVersion).jpeg"
            }
            
            AWSS3PreSignedURLBuilder.default().getPreSignedURL(request).continueWith { (task:AWSTask<NSURL>) -> Any? in
                if let error = task.error {
                    print("Error: \(error)")
                    return nil
                }
                
                let presignedURL = task.result
                DispatchQueue.main.async {
                    let options = ImageLoadingOptions(failureImage: UIImage(named: "removedImage"))
                    Nuke.loadImage(with: presignedURL!.absoluteURL!, options: options, into: self.initialIVLeft)
                }
                
                return nil
            }
        }
        else { //right
            if editVersion == 0 {
                request.key = postID + "-right.jpeg"
            }
            else{
                request.key = postID + "-right\(editVersion).jpeg"
            }
            
            AWSS3PreSignedURLBuilder.default().getPreSignedURL(request).continueWith { (task:AWSTask<NSURL>) -> Any? in
                if let error = task.error {
                    print("Error: \(error)")
                    return nil
                }
                
                let presignedURL = task.result
                DispatchQueue.main.async {
                    let options = ImageLoadingOptions(failureImage: UIImage(named: "removedImage"))
                    Nuke.loadImage(with: presignedURL!.absoluteURL!, options: options, into: self.initialIVRight)
                }
                
                return nil
            }
        }
        
    }
}
