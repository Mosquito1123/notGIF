//
//  SLRequestManger.swift
//  notGIF
//
//  Created by Atuooo on 15/10/2016.
//  Copyright © 2016 xyz. All rights reserved.
//
import UIKit
import Photos
import Social
import Accounts
import MobileCoreServices

fileprivate typealias JSON = [String: AnyObject]
fileprivate typealias PostCompletion = (_ result: PostResult) -> Void

fileprivate enum Result {
    case success(JSON)
    case wrong(String)
    case failed(String)
}

fileprivate enum PostResult {
    case success(JSON)
    case failed(String)
}

final class SLRequestManager {
    
    class func shareGIF(with gifData: Data, and message: String, to account: ACAccount) {
        
        switch account.accountType.identifier {
            
        case ACAccountTypeIdentifierSinaWeibo:
            // 👉 http://open.weibo.com/wiki/2/statuses/upload
            
            let postURL = URL(string: "https://upload.api.weibo.com/2/statuses/upload.json")!
            
            guard let postRequest = SLRequest(forServiceType: SLServiceTypeSinaWeibo, requestMethod: .POST, url: postURL, parameters: ["status": message]) else {
                StatusBarToast.show(.requestFailed)
                return
            }
            
            StatusBarToast.show(.posting)

            postRequest.account = account
            postRequest.addMultipartData(gifData, withName: "pic", type: "image/gif", filename: nil)
            
            postRequest.perform { result in
                
                switch result {
                case .success:
                    StatusBarToast.show(.postSuccess)
                    
                case .failed(let err):
                    StatusBarToast.show(.postFailed(err))
                }
            }
            
        case ACAccountTypeIdentifierTwitter:
            
            // 👉 https://dev.twitter.com/rest/reference/post/media/upload
            // 先上传 gif 获取 media_id
            let uploadURL = URL(string: "https://upload.twitter.com/1.1/media/upload.json")!
            let dataStr = gifData.base64EncodedString(options: .lineLength64Characters)
            let uploadParameters = ["media": dataStr]
            
            guard let uploadRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .POST, url: uploadURL, parameters: uploadParameters) else {
                StatusBarToast.show(.requestFailed)
                return
            }
            
            StatusBarToast.show(.posting)
            
            uploadRequest.account = account
            uploadRequest.perform { uploadResult in
                
                switch uploadResult {
                    
                case .success(let json):
                    
                    // 获取 mediaID 后发送 tweet
                    guard let mediaID = json["media_id_string"] as? String else {
                        StatusBarToast.show(.postFailed("can't upload gif"))
                        return
                    }
                    
                    let postParameters = [
                        "status": message,
                        "media_ids": mediaID
                    ]
                    
                    let postURL = URL(string: "https://api.twitter.com/1.1/statuses/update.json")!
                    
                    guard let postRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .POST, url: postURL, parameters: postParameters) else {
                        StatusBarToast.show(.requestFailed)
                        return
                    }
                    
                    postRequest.account = account
                    postRequest.perform { postResult in
                        
                        switch postResult {
                            
                        case .success:
                            StatusBarToast.show(.postSuccess)
                            
                        case .failed(let err):
                            StatusBarToast.show(.postFailed(err))
                        }
                    }
                    
                case .failed(let err):
                    StatusBarToast.show(.postFailed(err))
                }
            }
            
        default:
            break
        }
    }
}

fileprivate extension SLRequest {
    
    func perform(completionHandler: @escaping PostCompletion) {
        
        perform { (data, response, err) in
            
            guard err == nil else {
                completionHandler(.failed(err!.localizedDescription))
                return
            }
            
            guard let data = data, let response = response,
                let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! JSON else {
                    completionHandler(.failed(String.trans_promptError))
                    return
            }
            
            if (200...299) ~= response.statusCode {
                completionHandler(.success(json))
                
            } else {
                if let errMessage = parseErrorInfo(with: json, of: self.account.accountType) {
                    completionHandler(.failed(errMessage))
                    
                } else {
                    let errStr = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
                    completionHandler(.failed(errStr))
                }
                
            }
        }
    }
}

fileprivate func parseErrorInfo(with json: JSON, of type: ACAccountType) -> String? {
    
    var errMessage: String?
    
    switch type.identifier {
        
    case ACAccountTypeIdentifierTwitter: // 👉 https://dev.twitter.com/overview/api/response-codes
        
        if let error = (json["errors"] as? Array<JSON>)?.first,
            let message = error["message"] as? String {
            errMessage = message
        }
        
    case ACAccountTypeIdentifierSinaWeibo:  // 👉 http://open.weibo.com/wiki/Error_code
        
        if let message = json["error"] as? String {
            errMessage = message
        }
        
    default:
        errMessage = "errorType: \(type.identifier)"
    }
    
    return errMessage
}
