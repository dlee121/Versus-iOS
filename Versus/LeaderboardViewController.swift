//
//  LeaderboardViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/13/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class LeaderboardViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var leaders = [LeaderboardEntry]()
    var apiClient = VSVersusAPIClient.default()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool){
        super.viewWillAppear(animated)
        apiClient.leaderboardGet(a: "lb").continueWith(block:) {(task: AWSTask) -> AnyObject? in
            if task.error != nil {
                DispatchQueue.main.async {
                    print(task.error!)
                }
            }
            else {
                let results = task.result?.hits?.hits
                
                for item in results! {
                    self.leaders.append(LeaderboardEntry(itemSource: item.source!))
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            }
            return nil
        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return leaders.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
            case 0:
                return CGFloat(123.0)
            case 1:
                return CGFloat(107.0)
            default:
                return CGFloat(85.0)
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "goldLeader", for: indexPath) as? GoldLeaderTableViewCell
            return cell!
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "silverLeader", for: indexPath) as? SilverLeaderTableViewCell
            return cell!
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "bronzeLeader", for: indexPath) as? BronzeLeaderTableViewCell
            return cell!
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "plainLeader", for: indexPath) as? PlainLeaderTableViewCell
            return cell!
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
