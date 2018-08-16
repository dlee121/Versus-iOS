//
//  TabBarViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 8/15/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class TabBarViewController: UITabBarController {

    let button = UIButton.init(type: .custom)
    var previousTabNum = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        addCenterButton(withImage: #imageLiteral(resourceName: "main_fab"), highlightImage: #imageLiteral(resourceName: "main_fab"))
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        //necessary in case user taps the actual middle tap element exposed below the center button instead of tapping the center button
        previousTabNum = selectedIndex
    }
    
    func createPostBack(){
        selectedIndex = previousTabNum
        tabBar.isHidden = false
    }
    
    @objc
    func handleTouchTabbarCenter(sender : UIButton)
    {
        if let count = self.tabBar.items?.count
        {
            let i = floor(Double(count / 2))
            previousTabNum = selectedIndex
            self.selectedViewController = self.viewControllers?[Int(i)]
        }
    }
    
    func addCenterButton(withImage buttonImage : UIImage, highlightImage: UIImage) {
        
        let paddingBottom : CGFloat = 10.0
        let diameter : CGFloat = 58
        
        button.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin, .flexibleLeftMargin, .flexibleBottomMargin]
        button.frame = CGRect(x: 0.0, y: 0.0, width: diameter, height: diameter)
        button.setBackgroundImage(buttonImage, for: .normal)
        button.setBackgroundImage(highlightImage, for: .highlighted)
        
        let rectBoundTabbar = self.tabBar.bounds
        let xx = rectBoundTabbar.midX
        let yy = rectBoundTabbar.midY - paddingBottom
        button.center = CGPoint(x: xx, y: yy)
        
        self.tabBar.addSubview(button)
        self.tabBar.bringSubview(toFront: button)
        (self.tabBar as! CustomTabBar).middleButton = button
        (self.tabBar as! CustomTabBar).radius = diameter/2
        
        button.addTarget(self, action: #selector(handleTouchTabbarCenter), for: .touchUpInside)
        
        if let count = self.tabBar.items?.count
        {
            let i = floor(Double(count / 2))
            let item = self.tabBar.items![Int(i)]
            item.title = ""
        }
    }

    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // safe place to set the frame of button manually
        //button.frame = CGRect.init(x: self.tabBar.center.x - 32, y: self.view.bounds.height - 74, width: 64, height: 64)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}

