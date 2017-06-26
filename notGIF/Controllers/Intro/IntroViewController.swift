//
//  IntroViewController.swift
//  notGIF
//
//  Created by Atuooo on 24/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

class IntroViewController: UIViewController {

    fileprivate var currentIndex = 0
    
    @IBOutlet var rightSwipeGes: UISwipeGestureRecognizer!
    @IBOutlet var leftSwipeGes: UISwipeGestureRecognizer!
    
    @IBOutlet weak var sloganView: IntroView!
    
    fileprivate var introViews: [Intro] = []
    
    @IBAction func leftSwipeGesHandler(_ sender: UISwipeGestureRecognizer) {
        guard currentIndex < 2 else { return }
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
        let introTagView = IntroTagView()
        let introShareView = IntroShareView()
        
        introTagView.transform = CGAffineTransform(translationX: kScreenWidth, y: 0)
        introTagView.alpha = 0.3
        
        introShareView.transform = CGAffineTransform(translationX: kScreenWidth, y: 0)
        introShareView.alpha = 0.3
        
        introShareView.goMainHandler = {
            NGUserDefaults.haveShowIntro = true
            
            UIApplication.shared.keyWindow?.set(rootViewController: UIStoryboard.main)
        }
        
        view.addSubview(introTagView)
        view.addSubview(introShareView)
        
        introViews = [sloganView, introTagView, introShareView]
    }
    
    deinit {
        printLog("deinited")
    }
}
