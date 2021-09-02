//
//  CustomHTTPProtocol.swift
//  AgendaDottori
//
//  Created by Paolo Musolino on 04/02/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import Foundation

public class CustomHTTPProtocol: URLProtocol {
    static var ignoredHosts = [String]()
    @available(*, deprecated, renamed: "ignoredHosts")
    static var blacklistedHosts: [String] {
        get {
            return ignoredHosts
        }
        set {
            ignoredHosts = newValue
        }
    }

    struct Constants {
        static let RequestHandledKey = "URLProtocolRequestHandled"
    }
    
    var session: URLSession?
    var sessionTask: URLSessionDataTask?
    var currentRequest: RequestModel?
    
    override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        super.init(request: request, cachedResponse: cachedResponse, client: client)
        
        if session == nil {
            session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        }
    }
    
    override public class func canInit(with request: URLRequest) -> Bool {
        guard CustomHTTPProtocol.shouldHandleRequest(request) else { return false }

        if CustomHTTPProtocol.property(forKey: Constants.RequestHandledKey, in: request) != nil {
            return false
        }
        return true
    }
    
    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override public func startLoading() {
        let newRequest = ((request as NSURLRequest).mutableCopy() as? NSMutableURLRequest)!
        CustomHTTPProtocol.setProperty(true, forKey: Constants.RequestHandledKey, in: newRequest)
        sessionTask = session?.dataTask(with: newRequest as URLRequest)
        sessionTask?.resume()
        
        currentRequest = RequestModel(request: newRequest, session: session)
        Storage.shared.saveRequest(request: currentRequest)
    }
    
    override public func stopLoading() {
        sessionTask?.cancel()
        currentRequest?.httpBody = body(from: request)
        if let startDate = currentRequest?.date{
            currentRequest?.duration = fabs(startDate.timeIntervalSinceNow) * 1000 //Find elapsed time and convert to milliseconds
        }

        Storage.shared.saveRequest(request: currentRequest)
        session?.invalidateAndCancel()
    }
    
    private func body(from request: URLRequest) -> Data? {
        /// The receiver will have either an HTTP body or an HTTP body stream only one may be set for a request.
        /// A HTTP body stream is preserved when copying an NSURLRequest object,
        /// but is lost when a request is archived using the NSCoding protocol.
        return request.httpBody ?? request.httpBodyStream?.readfully()
    }

    /// Inspects the request to see if the host has not been blacklisted and can be handled by this URL protocol.
    /// - Parameter request: The request being processed.
    private class func shouldHandleRequest(_ request: URLRequest) -> Bool {
        guard let host = request.url?.host else { return false }

        return CustomHTTPProtocol.ignoredHosts.filter({ host.hasSuffix($0) }).isEmpty
    }
    
    deinit {
        session = nil
        sessionTask = nil
        currentRequest = nil
    }
}

extension CustomHTTPProtocol: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        client?.urlProtocol(self, didLoad: data)
        if currentRequest?.dataResponse == nil{
            currentRequest?.dataResponse = data
        }
        else{
            currentRequest?.dataResponse?.append(data)
        }
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        let policy = URLCache.StoragePolicy(rawValue: request.cachePolicy.rawValue) ?? .notAllowed
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: policy)
        currentRequest?.initResponse(response: response)
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            currentRequest?.errorClientDescription = error.localizedDescription
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
        completionHandler(request)
    }
    
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        guard let error = error else { return }
        currentRequest?.errorClientDescription = error.localizedDescription
        client?.urlProtocol(self, didFailWithError: error)
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let wrappedChallenge = URLAuthenticationChallenge(authenticationChallenge: challenge, sender: CustomAuthenticationChallengeSender(handler: completionHandler))
        client?.urlProtocol(self, didReceive: wrappedChallenge)
    }
    
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        client?.urlProtocolDidFinishLoading(self)
    }
}

final class CustomAuthenticationChallengeSender: NSObject, URLAuthenticationChallengeSender {
    typealias CustomAuthenticationChallengeHandler = (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    let handler: CustomAuthenticationChallengeHandler
    
    init(handler: @escaping CustomAuthenticationChallengeHandler) {
        self.handler = handler
    }

    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {
        handler(.useCredential, credential)
    }
    
    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {
        handler(.useCredential, nil)
    }
    
    func cancel(_ challenge: URLAuthenticationChallenge) {
        handler(.cancelAuthenticationChallenge, nil)
    }
    
    func performDefaultHandling(for challenge: URLAuthenticationChallenge) {
        handler(.performDefaultHandling, nil)
    }
    
    func rejectProtectionSpaceAndContinue(with challenge: URLAuthenticationChallenge) {
        handler(.rejectProtectionSpace, nil)
    }
}
