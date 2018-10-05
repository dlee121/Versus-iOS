//
//  GDPRConsentViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 10/5/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import ActiveLabel
import Appodeal

class GDPRConsentViewController: UIViewController {

    
    @IBOutlet weak var legalText: ActiveLabel!
    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet weak var noLabel: UILabel!
    
    @IBOutlet weak var textTop: NSLayoutConstraint!
    @IBOutlet weak var yesTop: NSLayoutConstraint!
    @IBOutlet weak var noTop: NSLayoutConstraint!
    @IBOutlet weak var noTextTop: NSLayoutConstraint!
    
    
    var screenHeight : CGFloat!
    
    var yesTapped = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        screenHeight = UIScreen.main.bounds.height
        
        if screenHeight < 666 { //adjust for smaller/lower-density screens
            noLabel.font = noLabel.font.withSize(14)
            textTop.constant /= 1.5
            yesTop.constant /= 1.5
            noTop.constant /= 1.5
            noTextTop.constant /= 1.5
        }
        
        // Do any additional setup after loading the view.
        yesButton.layer.cornerRadius = 5.0
        yesButton.clipsToBounds = true
        
        let customType1 = ActiveType.custom(pattern: "\\sLearn More\\b")
        legalText.enabledTypes.append(customType1)
        legalText.customize { label in
            legalText.customColor[customType1] = UIColor(red: 0.0, green: 122.0/255, blue: 1, alpha: 1)
            
            legalText.handleCustomTap(for: customType1) { _ in
                guard let url = URL(string: "https://www.appodeal.com/privacy-policy") else { return }
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url)
                } else {
                    // Fallback on earlier versions
                    UIApplication.shared.openURL(url)
                }
            }
        }
        
        noLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(noTapped)))
        
    }
    
    
    @IBAction func yesTapped(_ sender: UIButton) {
        yesTapped = true
        performSegue(withIdentifier: "showAdConsentFinish", sender: self)
    }
    
    @objc func noTapped() {
        yesTapped = false
        performSegue(withIdentifier: "showAdConsentFinish", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let adConsentFinalVC = segue.destination as? GDPRFinalViewController else {return}
        let view = adConsentFinalVC.view
        
        if yesTapped {
            Appodeal.initialize(withApiKey: "819054921bcb6cc21aa0e7a19f852d182975592b907d0ad3", types: .nativeAd, hasConsent: true)
            
            //set local bd = "gdpr1"
            //set ES bd = "gdpr1"
            
            
            adConsentFinalVC.textLabel.text = "Great. We hope you enjoy your personalized ad experience. You can withdraw your consent at any time by enabling \"Limit Ad Tracking\" under Settings/Privacy/Advertising on your iOS device and then restarting this app."
        }
        else {
            Appodeal.initialize(withApiKey: "819054921bcb6cc21aa0e7a19f852d182975592b907d0ad3", types: .nativeAd, hasConsent: false)
            
            //set local bd = "gdpr0"
            //set ES bd = "gdpr0"
            
            
            adConsentFinalVC.textLabel.text = "Appodeal won’t collect your data for personalized advertising in this app."
        }
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
