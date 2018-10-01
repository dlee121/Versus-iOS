//
//  LeaderboardViewController.swift
//  Versus
//
//  Created by Dongkeun Lee on 7/13/18.
//  Copyright © 2018 Versus. All rights reserved.
//

import UIKit

class LeaderboardViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    var leaders = [LeaderboardEntry]()
    var tappedUsername = ""
    
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Leaderboard"
        tableView.separatorStyle = .none
        // Do any additional setup after loading the view.
        
        // Add Refresh Control to Table View
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        
        // Configure Refresh Control
        refreshControl.addTarget(self, action: #selector(refreshList(_:)), for: .valueChanged)
        
    }
    
    @objc private func refreshList(_ sender: Any) {
        if !indicator.isAnimating {
            self.leaders.removeAll()
            self.tableView.reloadData()
            tableView.separatorStyle = .none
            
            VSVersusAPIClient.default().leaderboardGet(a: "lb").continueWith(block:) {(task: AWSTask) -> AnyObject? in
                if task.error != nil {
                    DispatchQueue.main.async {
                        print(task.error!)
                    }
                }
                else {
                    let results = task.result?.hits?.hits
                    self.leaders.removeAll()
                    
                    for item in results! {
                        self.leaders.append(LeaderboardEntry(itemSource: item.source!))
                    }
                    
                    DispatchQueue.main.async {
                        self.refreshControl.endRefreshing()
                        self.tableView.reloadData()
                        self.tableView.separatorStyle = .singleLine
                    }
                    
                }
                return nil
            }
        }
        else {
            self.refreshControl.endRefreshing()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    override func viewWillAppear(_ animated: Bool){
        super.viewWillAppear(animated)
        indicator.startAnimating()
        VSVersusAPIClient.default().leaderboardGet(a: "lb").continueWith(block:) {(task: AWSTask) -> AnyObject? in
            if task.error != nil {
                DispatchQueue.main.async {
                    print(task.error!)
                }
            }
            else {
                let results = task.result?.hits?.hits
                self.leaders.removeAll()
                
                for item in results! {
                    self.leaders.append(LeaderboardEntry(itemSource: item.source!))
                }
                
                DispatchQueue.main.async {
                    self.indicator.stopAnimating()
                    self.tableView.reloadData()
                    self.tableView.separatorStyle = .singleLine
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
        if(indexPath.row == 0){
            return CGFloat(116.0)
        }
        return CGFloat(102.0)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "goldLeader", for: indexPath) as? GoldLeaderTableViewCell
            cell!.setCell(item: leaders[indexPath.row])
            return cell!
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "silverLeader", for: indexPath) as? SilverLeaderTableViewCell
            cell!.setCell(item: leaders[indexPath.row])
            return cell!
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "bronzeLeader", for: indexPath) as? BronzeLeaderTableViewCell
            cell!.setCell(item: leaders[indexPath.row])
            return cell!
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "plainLeader", for: indexPath) as? PlainLeaderTableViewCell
            cell!.setCell(item: leaders[indexPath.row], rankNumber: indexPath.row + 1)
            return cell!
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tappedUsername = leaders[indexPath.row].username
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "leaderboardToProfile", sender: self)
    }
    
    func scrollOrRefresh() {
        if tableView != nil  && leaders != nil && leaders.count > 0 && !indicator.isAnimating && !refreshControl.isRefreshing {
            if tableView.contentOffset.y <= 0.0 {
                refreshControl.beginRefreshing()
                refreshList(0)
            }
            else {
                tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let profileVC = segue.destination as? ProfileViewController else {return}
        profileVC.fromPostPage = false
        profileVC.currentUsername = tappedUsername
        let backItem = UIBarButtonItem()
        backItem.title = "Leader..."
        //backItem.setTitleTextAttributes([NSAttributedStringKey.font: UIFont.systemFont(ofSize: 12.0)], for: .normal)
        navigationItem.backBarButtonItem = backItem
        //categoryVC.categoryQuery(fromIndex: 0, category: selectedCategory)
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
