//
//  NotificationsTableViewCell.swift
//  Versus
//
//  Created by Dongkeun Lee on 8/17/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class SettingsItemTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var settingName: UILabel!
    
    
    func setCell(name : String){
        settingName.text = name
    }
    
    
}
