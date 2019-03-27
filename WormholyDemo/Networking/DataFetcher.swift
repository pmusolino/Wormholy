//
//  DataFetcher.swift
//  Wormholy-Demo-iOS
//
//  Created by Paolo Musolino on 18/01/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import Foundation

class DataFetcher: NSObject {

    var session : URLSession? //Session manager
    
    //MARK: Singleton
    static let sharedInstance = DataFetcher(managerCachePolicy: .reloadIgnoringLocalCacheData)
    
    //MARK: Init
    override init() {
        super.init()
    }
    
    init(managerCachePolicy:NSURLRequest.CachePolicy){
        super.init()
        self.configure(cachePolicy: managerCachePolicy)
    }
    
    //MARK: Session Configuration
    func configure(cachePolicy:NSURLRequest.CachePolicy?){
        let sessionConfiguration = URLSessionConfiguration.default //URLSessionConfiguration()
        sessionConfiguration.timeoutIntervalForRequest = 10.0
        sessionConfiguration.requestCachePolicy = cachePolicy != nil ? cachePolicy! : .reloadIgnoringLocalCacheData
        sessionConfiguration.httpAdditionalHeaders = ["Accept-Language": "en"]
        self.session = URLSession(configuration: sessionConfiguration)
    }
    
    
    //MARK: API Track
    func getPost(id: Int, completion: @escaping () -> Void, failure:@escaping (Error) -> Void){
        var urlRequest = Routing.Post(id).urlRequest
        urlRequest.httpMethod = "GET"
        
        let task = session?.dataTask(with: urlRequest) {
            (
            data, response, error) in
            
            guard response?.validate() == nil else{
                failure(response!.validate()!)
                return
            }
            DispatchQueue.main.async {
                completion()
            }
        }
        
        task?.resume()
    }
    
    func newPost(userId: Int, title: String, body: String, completion: @escaping () -> Void, failure:@escaping (Error) -> Void){
        var urlRequest = Routing.NewPost(userId: userId, title: title, body: body).urlRequest
        urlRequest.httpMethod = "POST"
        
        let task = session?.dataTask(with: urlRequest) {
            (
            data, response, error) in
            
            guard response?.validate() == nil else{
                failure(response!.validate()!)
                return
            }
            DispatchQueue.main.async {
                completion()
            }
        }
        
        task?.resume()
    }
    
    func getWrongURL(completion: @escaping () -> Void, failure:@escaping (Error) -> Void){
        var urlRequest = Routing.WrongURL(()).urlRequest
        urlRequest.httpMethod = "GET"
        
        let task = session?.dataTask(with: urlRequest) {
            (
            data, response, error) in
            
            guard response?.validate() == nil else{
                failure(response!.validate()!)
                return
            }
            DispatchQueue.main.async {
                completion()
            }
        }
        
        task?.resume()
    }
    
    func getPhotosList(completion: @escaping () -> Void, failure:@escaping (Error) -> Void){
        var urlRequest = Routing.Photos(()).urlRequest
        urlRequest.httpMethod = "GET"
        
        let task = session?.dataTask(with: urlRequest) {
            (
            data, response, error) in
            
            guard response?.validate() == nil else{
                failure(response!.validate()!)
                return
            }
            DispatchQueue.main.async {
                completion()
            }
        }
        
        task?.resume()
    }
}

