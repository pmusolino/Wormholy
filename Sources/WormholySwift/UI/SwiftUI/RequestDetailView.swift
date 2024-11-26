//
//  RequestDetailView.swift
//  Wormholy
//
//  Created by Paolo Musolino on 21/11/24.
//

import SwiftUI

struct RequestDetailView: View {
    var request: RequestModel
    
    var body: some View {
        List {
            
            Section("Overview") {
                Text(RequestModelBeautifier.overview(request: request))
            }
            
            Section("Request Header") {
                Text(RequestModelBeautifier.header(request.headers))
            }
            
            Section("Request Body") {
                if let httpBody = request.httpBody {
                    NavigationLink(destination: BodyDetailView(dataBody: httpBody)) {
                        Text("View body")
                            .foregroundColor(.blue)
                    }
                } else {
                    Text("No body available")
                }
            }
            
            Section("Response Header") {
                Text(RequestModelBeautifier.header(request.responseHeaders))
            }
            
            Section("Response Body") {
                if let dataResponse = request.dataResponse {
                    NavigationLink(destination: BodyDetailView(dataBody: dataResponse)) {
                        Text("View body")
                            .foregroundColor(.blue)
                    }
                } else {
                    Text("No body available")
                }
            }
            
            if let errorDescription = request.errorClientDescription {
                Section("Error") {
                    Text("**Error**: \(errorDescription)")
                        .foregroundColor(.red)
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationTitle(URL(string: request.url)?.path ?? "Request Detail")
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

struct RequestDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a fake request for preview
        let fakeRequest = RequestModel(
            id: UUID().uuidString,
            url: "https://example.com/api/v1/resources/items/12345/details?include=all&expand=full",
            host: "example.com",
            port: 443,
            scheme: "https",
            date: Date(),
            method: "GET",
            headers: [
                "Content-Type": "application/json",
                "Authorization": "Bearer token",
                "Accept": "application/json",
                "User-Agent": "Wormholy/1.0"
            ],
            credentials: ["user": "password"],
            cookies: "sessionid=abc123;",
            httpBody: nil,
            code: 200,
            responseHeaders: [
                "Content-Type": "application/json",
                "Cache-Control": "no-cache",
                "Server": "Apache/2.4.41 (Ubuntu)"
            ],
            dataResponse: nil,
            errorClientDescription: nil,
            duration: 1.23
        )
        
        // Create a fake request with an error for preview
        let fakeErrorRequest = RequestModel(
            id: UUID().uuidString,
            url: "https://example.com/api/v1/resources/items/12345/details?include=all&expand=full",
            host: "example.com",
            port: 443,
            scheme: "https",
            date: Date(),
            method: "GET",
            headers: [
                "Content-Type": "application/json",
                "Authorization": "Bearer token",
                "Accept": "application/json",
                "User-Agent": "Wormholy/1.0"
            ],
            credentials: ["user": "password"],
            cookies: "sessionid=abc123;",
            httpBody: nil,
            code: 500,
            responseHeaders: [
                "Content-Type": "application/json",
                "Cache-Control": "no-cache",
                "Server": "Apache/2.4.41 (Ubuntu)"
            ],
            dataResponse: nil,
            errorClientDescription: "Internal Server Error",
            duration: 1.23
        )
        
        return Group {
            RequestDetailView(request: fakeRequest)
            RequestDetailView(request: fakeErrorRequest)
        }
    }
}
