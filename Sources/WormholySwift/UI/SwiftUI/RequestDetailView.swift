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
                Text(RequestModelBeautifier.body(request.httpBody))
            }
            
            Section("Response Header") {
                Text(RequestModelBeautifier.header(request.responseHeaders))
            }
            
            Section("Response Body") {
                Text(RequestModelBeautifier.body(request.dataResponse))
            }
            
            if let errorDescription = request.errorClientDescription {
                Section("Error") {
                    Text("**Error**: \(errorDescription)")
                        .foregroundColor(.red)
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle("Request Detail", displayMode: .inline)
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
        return RequestDetailView(request: fakeRequest)
    }
}
