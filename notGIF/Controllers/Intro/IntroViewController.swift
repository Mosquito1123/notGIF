//
//  IntroViewController.swift
//  notGIF
//
//  Created by Atuooo on 22/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

class IntroViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControlStackView: UIStackView!
    
    fileprivate var currentIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        makeUI()
    }
    
    @IBAction func dismissButtonClicked(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    fileprivate func makeUI() {
        let intros: [UIViewController] = [
            UIStoryboard.introA,
            UIStoryboard.introB,
            UIStoryboard.introC
        ]
        
        intros.forEach { intro in
            intro.view.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(intro.view)
            addChildViewController(intro)
            intro.didMove(toParentViewController: self)
        }
        
        let views: [String: Any] = [
            "view": view,
            "introA": intros[0].view,
            "introB": intros[1].view,
            "introC": intros[2].view
        ]
        
        let vConstranints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[introA(==view)]|", options: [], metrics: nil, views: views)
        NSLayoutConstraint.activate(vConstranints)
        
        let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[introA(==view)][introB(==view)][introC(==view)]|", options: [.alignAllBottom, .alignAllTop], metrics: nil, views: views)
        NSLayoutConstraint.activate(hConstraints)
    }
}

extension IntroViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.bounds.width
        let pageFraction = scrollView.contentOffset.x / pageWidth
        let count = Int(scrollView.contentSize.width / scrollView.bounds.width)
        
        let page = max(0, min(Int(round(pageFraction)), count))
        
        if page != currentIndex {
            let lineView = pageControlStackView.arrangedSubviews[currentIndex]
            pageControlStackView.insertArrangedSubview(lineView, at: page)
            currentIndex = page
        }
    }
}

