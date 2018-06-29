//
//  UIViewController+Toast.swift
//  Versus
//
//  Created by Dongkeun Lee on 6/28/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    func showToast(message : String) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 125, y: self.view.frame.size.height-100, width: 250, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        if let window = UIApplication.shared.windows.max(by: { $0.windowLevel < $1.windowLevel }), window !== self {
            window.addSubview(toastLabel)
        }
        //UIApplication.shared.windows.last?.addSubview(toastLabel)
        UIView.animate(withDuration: 1.0, delay: 1.5, options: .curveEaseIn, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
}
