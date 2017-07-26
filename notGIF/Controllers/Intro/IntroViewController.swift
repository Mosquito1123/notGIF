//
//  IntroViewController.swift
//  notGIF
//
//  Created by Atuooo on 24/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

class IntroViewController: UIViewController {

    static var isFromHelp: Bool = false
    
    fileprivate var currentIndex = 0
    
    @IBOutlet var rightSwipeGes: UISwipeGestureRecognizer!
    @IBOutlet var leftSwipeGes: UISwipeGestureRecognizer!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var sloganView: IntroView!
    
    fileprivate var introViews: [Intro] = []
    
    @IBAction func backButtonClicked(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func leftSwipeGesHandler(_ sender: UISwipeGestureRecognizer) {
        guard currentIndex < introViews.count - 1 else { return }
        view.isUserInteractionEnabled = false

        let toShowView = introViews[currentIndex+1]
        let toHideView = introViews[currentIndex]
        currentIndex += 1
        
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
            toShowView.show()
            toHideView.hide(toLeft: true)
            
        }) { _ in }
        
        DispatchQueue.main.after(0.5) {
            toShowView.animate()
            toHideView.restore()
            self.view.isUserInteractionEnabled = true
        }
    }
    
    @IBAction func rightSwipeGesHandler(_ sender: UISwipeGestureRecognizer) {
        guard currentIndex > 0 else { return }
        view.isUserInteractionEnabled = false
        
        let toShowView = introViews[currentIndex-1]
        let toHideView = introViews[currentIndex]
        
        currentIndex -= 1
        
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
            toShowView.show()
            toHideView.hide(toLeft: false)
            
        }) { _ in }
        
        DispatchQueue.main.after(0.5) { 
            toShowView.animate()
            toHideView.restore()
            self.view.isUserInteractionEnabled = true
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.barTint
        
        if !IntroViewController.isFromHelp {
            backButton.isHidden = true
        }
        
        let introTagView = IntroTagView()
        let introDetailView = IntroDetailView()
        let introShareView = IntroShareView()
        
        introTagView.transform = CGAffineTransform(translationX: kScreenWidth, y: 0)
        introTagView.alpha = 0.3
        
        introDetailView.transform = CGAffineTransform(translationX: kScreenWidth, y: 0)
        introDetailView.alpha = 0.3
        
        introShareView.transform = CGAffineTransform(translationX: kScreenWidth, y: 0)
        introShareView.alpha = 0.3
        
        introShareView.goMainHandler = { [weak self] in
            if IntroViewController.isFromHelp {
                self?.navigationController?.popViewController(animated: true)
            } else {
                NGUserDefaults.haveShowIntro = true
                UIApplication.shared.keyWindow?.set(rootViewController: UIStoryboard.main)
            }
        }
        
        view.addSubview(introTagView)
        view.addSubview(introDetailView)
        view.addSubview(introShareView)
        
        view.bringSubview(toFront: backButton)
        
        introViews = [sloganView, introTagView, introDetailView, introShareView]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    deinit {
        printLog("deinited")
    }
}
