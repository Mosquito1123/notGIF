//
//  UIStoryBoard+NG.swift
//  notGIF
//
//  Created by Atuooo on 22/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit

extension UIStoryboard {
    
    private static var pa_intro: UIStoryboard {
        return UIStoryboard(name: "Intro", bundle: nil)
    }
    
    static var intro: IntroViewController {
        return pa_intro.instantiateViewController(withIdentifier: "IntroViewController") as! IntroViewController
    }
    
    static var main: DrawerViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DrawerViewController") as! DrawerViewController
    }
    
    static var frameDetail: FrameDetailViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FrameDetailViewController") as! FrameDetailViewController
    }
    
    static var settingNav: BaseNavigationController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SettingNavigationController") as! BaseNavigationController
    }
}
