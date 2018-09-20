//
//  NativeAdTableViewCell.swift
//  Versus
//
//  Created by Dongkeun Lee on 9/19/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import Appodeal
import Nuke

class NativeAdTableViewCell: UITableViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var callToAction: UILabel!
    
    @IBOutlet weak var descr: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var mediaContainer: UIView!
    @IBOutlet weak var adChoices: UIView!
    
    @IBOutlet weak var mediaImageView: UIImageView!
    
    @IBOutlet weak var adChoicesBackupLabel: UILabel!
    
    func setCell(nativeAd : APDNativeAd, displayMainIMage : Bool) {
        title.text = nativeAd.title
        callToAction.text = nativeAd.callToActionText
        descr.text = nativeAd.descriptionText
        
        print("ad description = \(descr.text!)")
        
        if let iconImage = nativeAd.iconImage {
            Nuke.loadImage(with: iconImage.url, into: icon)
        }
        
        if displayMainIMage {
            if let mainImage = nativeAd.mainImage {
                Nuke.loadImage(with: mainImage.url, into: mediaImageView)
            }
        }
        
        if let adChoicesView = nativeAd.adChoicesView {
            adChoicesBackupLabel.isHidden = true
            adChoices = adChoicesView
        }
        else {
            adChoicesBackupLabel.isHidden = false
        }
        
    }

}

extension NativeAdTableViewCell : APDNativeAdView {
    
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
        return mediaContainer
    }
    
    func adChoicesView() -> UIView {
        return adChoices
    }
    
    static func nib() -> UINib {
        return UINib.init(nibName: "Native", bundle: Bundle.main)
    }
}
