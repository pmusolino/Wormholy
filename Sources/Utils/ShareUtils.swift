//
//  ShareUtils.swift
//  Wormholy-iOS
//
//  Created by Daniele Saitta on 15/02/2020.
//  Copyright © 2020 Wormholy. All rights reserved.
//

import Foundation

final class ShareUtils {

    static func shareRequests(presentingViewController: UIViewController, sender: UIBarButtonItem, requests: [RequestModel], requestExportOption: RequestExportOption = .flat){
         var text = ""
         for request in requests{
             switch requestExportOption {
             case .flat:
                 text = text + RequestModelBeautifier.txtExport(request: request)
             case .curl:
                 text = text + RequestModelBeautifier.curlExport(request: request)
             }
         }
         let textShare = [text]
        let customItem = CustomActivity(title: "Save to the desktop".localized, image: UIImage(named: "activity_icon", in: WHBundle.getBundle(), compatibleWith: nil)) { (sharedItems) in
             guard let sharedStrings = sharedItems as? [String] else { return }
            
            let dateFormatterGet = DateFormatter()
            dateFormatterGet.dateFormat = "yyyyMMdd_HHmmss_SSS"
             
             for string in sharedStrings {
                 FileHandler.writeTxtFileOnDesktop(text: string, fileName: "\(dateFormatterGet.string(from: Date()))-wormholy.txt")
             }
         }
         let activityViewController = UIActivityViewController(activityItems: textShare, applicationActivities: [customItem])
         activityViewController.popoverPresentationController?.barButtonItem = sender
         presentingViewController.present(activityViewController, animated: true, completion: nil)
     }
}
