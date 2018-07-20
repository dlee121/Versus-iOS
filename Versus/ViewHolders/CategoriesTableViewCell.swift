//
//  CategoriesTableViewCell.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/19/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class CategoriesTableViewCell: UITableViewCell {

    @IBOutlet weak var categoryImage: UIImageView!
    @IBOutlet weak var categoryName: UILabel!
    
    func setCell(name : String, image : UIImage){
        categoryImage.image = image
        categoryName.text = name
    }
    
    
    

}
