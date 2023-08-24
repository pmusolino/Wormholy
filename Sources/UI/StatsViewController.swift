//
//  StatsViewController.swift
//  Wormholy-iOS
//
//  Created by Aakash Tandukar on 29/06/2023.
//  Copyright © 2023 Wormholy. All rights reserved.
//

import UIKit

class StatsViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var totalRequestsLabel: UILabel!
    @IBOutlet weak var successRequestLabel: UILabel!
    @IBOutlet weak var errorRequestLabel: UILabel!
    @IBOutlet weak var totalSendBytesLabel: UILabel!
    @IBOutlet weak var totalReceivedBytesLabel: UILabel!
    @IBOutlet weak var averageRequestTimeLabel: UILabel!
    @IBOutlet weak var maxRequestTimeLabel: UILabel!
    @IBOutlet weak var minRequestTimeLabel: UILabel!
    @IBOutlet weak var getRequestLabel: UILabel!
    @IBOutlet weak var postRequestLabel: UILabel!
    @IBOutlet weak var deleteRequestLabel: UILabel!
    @IBOutlet weak var putRequestLabel: UILabel!
    @IBOutlet weak var patchRequestLabel: UILabel!
    @IBOutlet weak var securedRequestLabel: UILabel!
    @IBOutlet weak var unsecuredRequestLabel: UILabel!
    
    //MARK: - Properties
    var filteredRequests: [RequestModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        configDataWithViews()
    }
    
    func configDataWithViews(){
        
        var successRequests: Int = 0
        var errorRequests: Int = 0
        var totalReceivedData = Data()
        var totalsendData = Data()
        
        var getRequests: Int = 0
        var postRequests: Int = 0
        var deleteRequests: Int = 0
        var putRequests: Int = 0
        var patchRequests: Int = 0
        var securedRequests: Int = 0
        var unsecuredRequests: Int = 0
        var duractionArray = [Double]()
        
        
        guard filteredRequests.count > 0 else{
            return
        }
        
        
        var durationSum = Double()
        for (index, value) in filteredRequests.enumerated() {
            
            duractionArray.append(value.duration ?? 0)
            totalReceivedData.append(value.dataResponse ?? Data())
            totalsendData.append(value.httpBody ?? Data())
            durationSum += value.duration ?? 0
            
            
            switch value.code {
            case 200..<300:
                successRequests += 1
            case 300..<400:
                errorRequests += 1
            case 400..<500:
                errorRequests += 1
            case 500..<600:
                errorRequests += 1
            default:
                errorRequests += 1
            }
            
            print(value.method)
            if value.method == "GET"{
                getRequests += 1
            } else if value.method == "POST"{
                postRequests += 1
            } else if value.method == "PUT"{
                putRequests += 1
            } else if value.method == "PATCH"{
                patchRequests += 1
            } else if value.method == "DELETE"{
                deleteRequests += 1
            }
            
            if value.url.hasPrefix("https://") {
                securedRequests += 1
            } else{
                unsecuredRequests += 1
            }
        }
        
        var  averageDuration : Double = Double(durationSum) / Double(filteredRequests.count)
        
        self.totalRequestsLabel.text = "\(self.filteredRequests.count)"
        self.totalReceivedBytesLabel.text = "\(totalReceivedData)"
        self.totalSendBytesLabel.text = "\(totalsendData)"
        self.successRequestLabel.text = "\(successRequests)"
        self.errorRequestLabel.text = "\(errorRequests)"
        self.getRequestLabel.text = "\(getRequests)"
        self.postRequestLabel.text = "\(postRequests)"
        self.putRequestLabel.text = "\(putRequests)"
        self.patchRequestLabel.text = "\(patchRequests)"
        self.deleteRequestLabel.text = "\(deleteRequests)"
        self.securedRequestLabel.text = "\(securedRequests)"
        self.unsecuredRequestLabel.text = "\(unsecuredRequests)"
        self.averageRequestTimeLabel.text = "\(averageDuration.formattedMilliseconds())"
        self.maxRequestTimeLabel.text = "\(duractionArray.max()!.formattedMilliseconds())"
        self.minRequestTimeLabel.text = "\(duractionArray.min()!.formattedMilliseconds())"
        
    }
}
