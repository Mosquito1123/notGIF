//
//  MessageComposeViewController.swift
//  notGIF
//
//  Created by Atuooo on 11/06/2017.
//  Copyright © 2017 xyz. All rights reserved.
//

import UIKit
import MessageUI
import MobileCoreServices

class MessageComposeViewController: MFMessageComposeViewController, MFMessageComposeViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    convenience init?(gifData: Data) {
        guard MFMessageComposeViewController.canSendAttachments(),
            MFMessageComposeViewController.isSupportedAttachmentUTI(kUTTypeGIF as String) else {
            return nil
        }
        
        self.init()
        
        messageComposeDelegate = self
        addAttachmentData(gifData, typeIdentifier: kUTTypeGIF as String, filename: "not.gif")
        
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
}
