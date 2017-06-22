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
    
    static var introA: UIViewController {
        return pa_intro.instantiateViewController(withIdentifier: "IntroAViewController")
    }
    
    static var introB: UIViewController {
        return pa_intro.instantiateViewController(withIdentifier: "IntroBViewController")
    }

    static var introC: UIViewController {
        return pa_intro.instantiateViewController(withIdentifier: "IntroCViewController")
    }
}
