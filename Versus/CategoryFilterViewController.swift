//
//  LeaderboardViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/13/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class CategoryFilterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    var categories = [
        "Automobiles",
        "Cartoon/Anime/Fiction",
        "Celebrity/Gossip",
        "Culture",
        "Education",
        "Electronics",
        "Fashion",
        "Finance",
        "Food/Restaurant",
        "Game/Entertainment",
        "Morality/Ethics/Law",
        "Movies/TV",
        "Music/Artists",
        "Politics",
        "Random",
        "Religion",
        "Science",
        "Social Issues",
        "Sports",
        "Technology",
        "Weapons"
    ]
    var apiClient = VSVersusAPIClient.default()
    var selectedCategory : Int!
    var tab2Or3 : Int!
    var originVC : UIViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool){
        super.viewWillAppear(animated)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    /*
     func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
     if(indexPath.row == 0){
     return CGFloat(116.0)
     }
     return CGFloat(102.0)
     }
     */
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoriesTableViewCell
            cell!.setCell(name: "Automobiles", image: #imageLiteral(resourceName: "Automobiles"))
            return cell!
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoriesTableViewCell
            cell!.setCell(name: "Cartoon/Anime/Fiction", image: #imageLiteral(resourceName: "Cartoon_Anime_Fiction"))
            return cell!
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoriesTableViewCell
            cell!.setCell(name: "Celebrity/Gossip", image: #imageLiteral(resourceName: "Celebrity_Gossip"))
            return cell!
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoriesTableViewCell
            cell!.setCell(name: "Culture", image: #imageLiteral(resourceName: "Culture"))
            return cell!
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoriesTableViewCell
            cell!.setCell(name: "Education", image: #imageLiteral(resourceName: "Education"))
            return cell!
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoriesTableViewCell
            cell!.setCell(name: "Electronics", image: #imageLiteral(resourceName: "Electronics"))
            return cell!
        case 6:
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoriesTableViewCell
            cell!.setCell(name: "Fashion", image: #imageLiteral(resourceName: "Fashion"))
            return cell!
        case 7:
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoriesTableViewCell
            cell!.setCell(name: "Finance", image: #imageLiteral(resourceName: "Finance"))
            return cell!
        case 8:
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoriesTableViewCell
            cell!.setCell(name: "Food/Restaurant", image: #imageLiteral(resourceName: "Food_Restaurant"))
            return cell!
        case 9:
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoriesTableViewCell
            cell!.setCell(name: "Game/Entertainment", image: #imageLiteral(resourceName: "Game_Entertainment"))
            return cell!
        case 10:
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoriesTableViewCell
            cell!.setCell(name: "Morality/Ethics/Law", image: #imageLiteral(resourceName: "Morality_Ethics_Law"))
            return cell!
        case 11:
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoriesTableViewCell
            cell!.setCell(name: "Movies/TV", image: #imageLiteral(resourceName: "Movies_TV"))
            return cell!
        case 12:
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoriesTableViewCell
            cell!.setCell(name: "Music/Artists", image: #imageLiteral(resourceName: "Music_Artists"))
            return cell!
        case 13:
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoriesTableViewCell
            cell!.setCell(name: "Politics", image: #imageLiteral(resourceName: "Politics"))
            return cell!
        case 14:
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoriesTableViewCell
            cell!.setCell(name: "Random", image: #imageLiteral(resourceName: "Random"))
            return cell!
        case 15:
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoriesTableViewCell
            cell!.setCell(name: "Religion", image: #imageLiteral(resourceName: "Religion"))
            return cell!
        case 16:
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoriesTableViewCell
            cell!.setCell(name: "Science", image: #imageLiteral(resourceName: "Science"))
            return cell!
        case 17:
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoriesTableViewCell
            cell!.setCell(name: "Social Issues", image: #imageLiteral(resourceName: "Social Issues"))
            return cell!
        case 18:
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoriesTableViewCell
            cell!.setCell(name: "Sports", image: #imageLiteral(resourceName: "Sports"))
            return cell!
        case 19:
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoriesTableViewCell
            cell!.setCell(name: "Technology", image: #imageLiteral(resourceName: "Technology"))
            return cell!
        case 20:
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoriesTableViewCell
            cell!.setCell(name: "Weapons", image: #imageLiteral(resourceName: "Weapons"))
            return cell!
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoriesTableViewCell
            cell!.setCell(name: "Random", image: #imageLiteral(resourceName: "Random"))
            return cell!
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCategory = indexPath.row
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch tab2Or3 {
        case 2:
            let tab2VC = originVC as? Tab2CollectionViewController
            tab2VC?.categorySelection = "\(indexPath.row)"
            tab2VC?.categorySelectionLabel.text = ""
            tab2VC?.categorySelectionLabel.addImageThenString(imageName: getCategoryIconName(categoryInt: indexPath.row), imageHeight: 30, suffix: getCategoryName(categoryInt: indexPath.row))
            //tab2VC?.categorySelectionLabel.addImage(imageName: "close", imageHeight: 14)
            tab2VC?.refresh()
            
        case 3:
            //we'll copy everything over from Tab2 once we're done there and replace tab2 names with tab3 names
            let tab3VC = originVC as? Tab3CollectionViewController
            //tab3VC?.categorySelection = "\(indexPath.row)"
            //call function to refresh New page
            
        default:
            let tab2VC = originVC as? Tab2CollectionViewController
            tab2VC?.categorySelection = "\(indexPath.row)"
            tab2VC?.refresh()
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    @IBAction func closeButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    func getCategoryIconName(categoryInt : Int) -> String{
        switch categoryInt {
        case 0:
            return "Automobiles"
        case 1:
            return "Cartoon_Anime_Fiction"
        case 2:
            return "Celebrity_Gossip"
        case 3:
            return "Culture"
        case 4:
            return "Education"
        case 5:
            return "Electronics"
        case 6:
            return "Fashion"
        case 7:
            return "Finance"
        case 8:
            return "Food_Restaurant"
        case 9:
            return "Game_Entertainment"
        case 10:
            return "Morality_Ethics_Law"
        case 11:
            return "Movies_TV"
        case 12:
            return "Music_Artists"
        case 13:
            return "Politics"
        case 14:
            return "Random"
        case 15:
            return "Religion"
        case 16:
            return "Science"
        case 17:
            return "Social Issues"
        case 18:
            return "Sports"
        case 19:
            return "Technology"
        case 20:
            return "Weapons"
        default:
            return "Random"
        }
    }
    
    func getCategoryName(categoryInt : Int) -> String{
        switch categoryInt {
        case 0:
            return " Automobiles  "
        case 1:
            return " Cartoon/Anime/Fiction  "
        case 2:
            return " Celebrity/Gossip  "
        case 3:
            return " Culture  "
        case 4:
            return " Education  "
        case 5:
            return " Electronics  "
        case 6:
            return " Fashion  "
        case 7:
            return " Finance  "
        case 8:
            return " Food/Restaurant  "
        case 9:
            return " Game/Entertainment  "
        case 10:
            return " Morality/Ethics/Law  "
        case 11:
            return " Movies/TV  "
        case 12:
            return " Music/Artists  "
        case 13:
            return " Politics  "
        case 14:
            return " Random  "
        case 15:
            return " Religion  "
        case 16:
            return " Science  "
        case 17:
            return " Social Issues  "
        case 18:
            return " Sports  "
        case 19:
            return " Technology  "
        case 20:
            return " Weapons  "
        default:
            return " Random  "
        }
        
        
        
        
    }
    
    
}
