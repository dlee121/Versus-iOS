//
//  CustomTabBar.swift
//  Versus
//
//  Created by Dongkeun Lee on 8/15/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class CustomTabBar: UITabBar {
    var middleButton : UIButton!
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        if middleButton != nil {
            let from = point
            let to = middleButton.center
            return sqrt((from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)) <= 29 ? middleButton : super.hitTest(point, with: event)
        }
        
        return super.hitTest(point, with: event)
        
    }
    
}
