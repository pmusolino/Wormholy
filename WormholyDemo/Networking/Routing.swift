//
//  Routing.swift
//  Wormholy-Demo-iOS
//
//  Created by Paolo Musolino on 18/01/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import Foundation

enum Routing{
    
    case Post(Int)
    case NewPost(userId: Int, title: String, body: String)
    case WrongURL(())
    case Photos(())
    
    var urlRequest: URLRequest{
        let touple : (path: String, parameters: [String: Any]?) = {
            switch self{
                
            case .Post(let param):
                return("/posts/\(param)", nil)
            case .NewPost(let userId, let title, let body):
                return("/posts/", ["userId": userId, "title": title, "body": body])
            case .WrongURL():
                return("/wrongURL/", nil)
            case .Photos():
                return("/photos", nil)
            }
        }()
        
        let url:URL = URL(string: API_BASE_URL)!
        
        var urlRequest = URLRequest(url: url.appendingPathComponent(touple.path))
        urlRequest.httpBody = Routing.createDataFromJSONDictionary(dataToSend: touple.parameters)
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        
        return urlRequest
    }
    
    
    static func createDataFromJSONDictionary(dataToSend: [String:Any]?) -> Data?{
        
        guard dataToSend != nil else{
            return nil
        }
        do{
            if JSONSerialization.isValidJSONObject(dataToSend! as NSDictionary){
                
                let json = try JSONSerialization.data(withJSONObject: dataToSend! as NSDictionary, options: JSONSerialization.WritingOptions.prettyPrinted)
                let data_string = String(data: json, encoding: String.Encoding.utf8)
                
                return data_string?.data(using: String.Encoding.utf8)
            }
        }
        catch{
            print("Error! Could not create JSON for server payload.")
            return nil
        }
        
        return nil
    }
}
