//
//  UIViewController + BackButton.swift
//  Versus
//
//  Created by Dongkeun Lee on 9/18/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import Foundation

/// Handle UINavigationBar's 'Back' button action
protocol  UINavigationBarBackButtonHandler {
    
    /// Should block the 'Back' button action
    ///
    /// - Returns: true - dot block，false - block
    func  shouldPopOnBackButton() -> Bool
}

extension UIViewController: UINavigationBarBackButtonHandler {
    //Do not block the "Back" button action by default, otherwise, override this function in the specified viewcontroller
    @objc func  shouldPopOnBackButton() -> Bool {
        return true
    }
}

extension UINavigationController: UINavigationBarDelegate {
    public func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool{
        guard let items = navigationBar.items else {
            return false
        }
        
        if viewControllers.count < items.count {
            return true
        }
        
        var shouldPop = true
        if let vc = topViewController, vc.responds(to: #selector(UIViewController.shouldPopOnBackButton)){
            shouldPop = vc.shouldPopOnBackButton()
        }
        
        if shouldPop{
            DispatchQueue.main.async {
                self.popViewController(animated: true)
            }
        }else{
            for aView in navigationBar.subviews{
                if aView.alpha > 0 && aView.alpha < 1{
                    aView.alpha = 1.0
                }
            }
        }
        return false
    }
}
