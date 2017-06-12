//
//  AccountTableViewController.swift
//  notGIF
//
//  Created by Atuooo on 13/10/2016.
//  Copyright © 2016 xyz. All rights reserved.
//

import UIKit
import Accounts

private let cellID = "AccountTableViewCell"

class AccountTableViewController: UITableViewController {
    
    public var composeVC: ComposeViewController!
    
    deinit {
        printLog(" deinited")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.backgroundColor = .clear
        tableView.tableFooterView = UIView()
        tableView.tintColor = .black
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return composeVC.accounts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        
        let account = composeVC.accounts[indexPath.item]
        cell.backgroundColor = .clear
        cell.textLabel?.text = account.accountDescription
        cell.accessoryType = account == composeVC.selectedAccount ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        composeVC.selectedAccount = composeVC.accounts[indexPath.item]
        composeVC.reloadConfigurationItems()
        composeVC.popConfigurationViewController()
    }
}
