//
//  SettingsViewController.swift
//  notGIF
//
//  Created by Atuooo on 24/07/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit
import Buglife

class SettingsViewController: UIViewController {
    
    enum Section: Int, CustomStringConvertible {
        case selectAction   = 0
        case setSpeed       = 10
        case help           = 20
        case report         = 21
        case comment        = 22
        
        static let rowCounts = [1, 1, 3]
        
        init?(ip: IndexPath) {
            self.init(rawValue: ip.section*10 + ip.item)
        }
        
        var indexPath: IndexPath {
            return IndexPath(row: rawValue%10, section: rawValue/10)
        }
        
        var description: String {
            switch self {
            case .selectAction, .setSpeed: return ""
            case .report:       return String.trans_titleReport
            case .comment:      return String.trans_titleRateAppStore
            case .help:         return String.trans_titleHelp
            }
        }
    }
    
    fileprivate lazy var titleLabel: NavigationTitleLabel = {
        return NavigationTitleLabel(title: String.trans_titleSettings)
    }()
    
    fileprivate lazy var versionLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: kScreenWidth, height: 70))
        label.text = "v\(Config.version)"
        label.textAlignment = .center
        label.font = UIFont.menlo(ofSize: 14)
        label.textColor = UIColor.textTint.withAlphaComponent(0.6)
        return label
    }()

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.backgroundColor = UIColor.hex(0x131313)
            tableView.bounces = false
            
            tableView.registerClassOf(SettingsCommonCell.self)
            tableView.registerClassOf(SpeedSettingCell.self)
            tableView.registerClassOf(SelectActionCell.self)
            tableView.tableFooterView = versionLabel
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.titleView = titleLabel
    }
    
    @IBAction func dismissItemClicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - TableView Delegate
extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.rowCounts.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Section.rowCounts[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(ip: indexPath) else { fatalError() }
        
        switch section {
        case .selectAction:
            let cell: SelectActionCell = tableView.dequeueReusableCell()
            return cell
            
        case .setSpeed:
            let cell: SpeedSettingCell = tableView.dequeueReusableCell()
            cell.speedLabel.text = NGUserDefaults.playSpeedInList.description
            return cell
            
        case .comment, .report, .help:
            let cell: SettingsCommonCell = tableView.dequeueReusableCell()
            let hideSeparator = indexPath.item == tableView.numberOfRows(inSection: indexPath.section) - 1
            cell.configureWith(section.description, hideSeparator: hideSeparator)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Section(ip: indexPath) else { return }
        
        switch section {
        case .setSpeed:
            showSpeedSetAlertVC()
            
        case .comment:
            if let url = URL(string: Config.appStoreCommentURL) {
                UIApplication.shared.openURL(url)
            }
            
        case .help:
            IntroViewController.isFromHelp = true
            performSegue(withIdentifier: "showHelp", sender: nil)
            
        case .report:
            Buglife.shared().presentReporter()
            
        case .selectAction:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = Section(ip: indexPath) else { fatalError() }
        
        switch section {
        case .selectAction:
            return SelectActionCell.height
        case .setSpeed, .comment, .report, .help:
            return 50
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = UIColor.clear
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
}

// MARK: - Helper Method
extension SettingsViewController {
    fileprivate func showSpeedSetAlertVC() {
        guard let cell = tableView.cellForRow(at: Section.setSpeed.indexPath) as? SpeedSettingCell else { return }
        
        let alertVC = UIAlertController(title: nil, message: String.trans_promptPlaySpeed, preferredStyle: .actionSheet)
        alertVC.view.tintColor = UIColor.black
        
        let normalAction = UIAlertAction(title: PlaySpeedInList.normal.description, style: .default) { _ in
            cell.speedLabel.text = PlaySpeedInList.normal.description
            NGUserDefaults.playSpeedInList = PlaySpeedInList.normal
        }
        
        let slowAction = UIAlertAction(title: PlaySpeedInList.slow.description, style: .default) { _ in
            cell.speedLabel.text = PlaySpeedInList.slow.description
            NGUserDefaults.playSpeedInList = PlaySpeedInList.slow
        }
        
        let cancelAction = UIAlertAction(title: String.trans_titleCancel, style: .cancel, handler: nil)
        alertVC.addAction(cancelAction)
        alertVC.addAction(normalAction)
        alertVC.addAction(slowAction)
        present(alertVC, animated: true, completion: nil)
    }
}
