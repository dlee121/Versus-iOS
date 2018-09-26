//
//  NativeView.swift
//  Versus
//
//  Created by Dongkeun Lee on 9/26/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import Appodeal

class NativeImageView: UIView {
    /*
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var callToAction: UILabel!
    @IBOutlet weak var descr: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var adChoices: UIView!
    @IBOutlet weak var backupAdLabel: UILabel!
    */
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var backupAdLabel: UILabel!
    @IBOutlet weak var adChoices: UIView!
    @IBOutlet weak var descr: UILabel!
    @IBOutlet weak var mediaView: UIView!
    @IBOutlet weak var callToAction: UILabel!
    
    
    
    override func draw(_ rect: CGRect) {
        //self.asxRound()
        
        self.icon.layer.cornerRadius = 5.0
        self.icon.layer.masksToBounds = true
        
        self.callToAction.layer.cornerRadius = 10.0
        self.callToAction.layer.masksToBounds = true
    }
    
    
}

extension NativeImageView : APDNativeAdView {
    
    func titleLabel() -> UILabel {
        return title
    }
    
    func callToActionLabel() -> UILabel {
        return callToAction
    }
    
    func descriptionLabel() -> UILabel {
        return descr
    }
    
    func iconView() -> UIImageView {
        return icon
    }
    
    func mediaContainerView() -> UIView {
        return mediaView
    }
    
    func adChoicesView() -> UIView {
        backupAdLabel.isHidden = true
        return adChoices
    }
    
    static func nib() -> UINib {
        return UINib.init(nibName: "NativeImage", bundle: Bundle.main)
    }
}
