//
//  MeViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/13/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import Firebase

class MeViewController: ButtonBarPagerTabStripViewController {

    override func viewDidLoad() {
        self.loadDesign()
        super.viewDidLoad()
        

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let child_1 = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CommentsHistory")
        let child_2 = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PostsHistory")
        return [child_1, child_2]
    }
    
    func loadDesign() {
        //self.settings.style.buttonBarHeight = 325.0
        self.settings.style.buttonBarBackgroundColor = UIColor(named: "VS_Red")
        self.settings.style.buttonBarItemBackgroundColor = UIColor(named: "VS_Blue")
        self.settings.style.selectedBarBackgroundColor = UIColor(named: "VS_Red")!
        self.settings.style.buttonBarItemFont = .boldSystemFont(ofSize: 13)
        self.settings.style.selectedBarHeight = 4.0
        self.settings.style.buttonBarMinimumLineSpacing = 0
        self.settings.style.buttonBarItemTitleColor = UIColor(named: "VS_Red")
        self.settings.style.buttonBarItemsShouldFillAvailableWidth = true
        self.settings.style.buttonBarLeftContentInset = 0
        self.settings.style.buttonBarRightContentInset = 0
        
        changeCurrentIndexProgressive = { (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in guard changeCurrentIndex == true else { return }
            oldCell?.label.textColor = .white
            newCell?.label.textColor = UIColor(named: "VS_Red")
        }
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
