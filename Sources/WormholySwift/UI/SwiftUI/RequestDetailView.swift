//
//  RequestDetailView.swift
//  Wormholy
//
//  Created by Paolo Musolino on 21/11/24.
//

import SwiftUI

internal struct RequestDetailView: View {
    @State private var showAlert = false
    @State private var alertMessage = ""
    @ObservedObject var request: RequestModel
    
    var body: some View {
        NavigationStack {
            List {
                
                // Overview Section
                Section(header: Text("Overview")) {
                    Text(RequestModelBeautifier.overview(request: request).0)
                        .onTapGesture {
                            // Copy the original overview text to clipboard
                            copyToClipboard(text: overviewText())
                        }
                }
                
                // Request Header Section
                Section(header: Text("Request Header")) {
                    Text(RequestModelBeautifier.header(request.headers).0)
                        .onTapGesture {
                            // Copy the original request header text to clipboard
                            copyToClipboard(text: headerText(request.headers))
                        }
                }
                
                // Request Body Section
                Section(header: Text("Request Body")) {
                    if let httpBody = request.httpBody {
                        NavigationLink(destination: BodyDetailView(dataBody: httpBody)) {
                            Text("View body")
                                .foregroundColor(.blue)
                        }
                    } else {
                        Text("No body available")
                    }
                }
                
                // Response Header Section
                Section(header: Text("Response Header")) {
                    Text(RequestModelBeautifier.header(request.responseHeaders).0)
                        .onTapGesture {
                            // Copy the original response header text to clipboard
                            copyToClipboard(text: headerText(request.responseHeaders))
                        }
                }
                
                // Response Body Section
                Section(header: Text("Response Body")) {
                    if let dataResponse = request.dataResponse {
                        NavigationLink(destination: BodyDetailView(dataBody: dataResponse)) {
                            Text("View body")
                                .foregroundColor(.blue)
                        }
                    } else {
                        Text("No body available")
                    }
                }
                
                // Error Section
                if let errorDescription = request.errorClientDescription {
                    Section(header: Text("Error")) {
                        Text("**Error**: \(errorDescription)")
                            .foregroundColor(.red)
                            .onTapGesture {
                                // Copy the error description to clipboard
                                copyToClipboard(text: errorDescription)
                            }
                    }
                }
            }
            .textSelection(.enabled)
            .listStyle(GroupedListStyle())
            .navigationTitle(URL(string: request.url)?.path ?? "Request Detail")
            .alert(isPresented: $showAlert) {
                // Show a non-blocking alert when text is copied
                Alert(title: Text("Copied"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    // Function to copy text to clipboard and show alert
    private func copyToClipboard(text: String) {
        UIPasteboard.general.string = text
        alertMessage = "Text copied to clipboard"
        showAlert = true
    }
    
    // Function to get the original overview text
    private func overviewText() -> String {
        let url = "URL: \(request.url)\n"
        let method = "Method: \(request.method)\n"
        let responseCode = "Response Code: \(request.code != 0 ? "\(request.code)" : "-")\n"
        let requestStartTime = "Request Start Time: \(request.date.stringWithFormat(dateFormat: "MMM d yyyy - HH:mm:ss") ?? "-")\n"
        let duration = "Duration: \(request.duration?.formattedMilliseconds() ?? "-")"
        return [url, method, responseCode, requestStartTime, duration].joined()
    }
    
    // Function to get the original header text
    private func headerText(_ headers: [String: String]?) -> String {
        guard let headerDictionary = headers else {
            return "-"
        }
        return headerDictionary.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
    }
    
    // Function to get the original body text
    private func bodyText(_ body: Data?) -> String {
        guard let body = body else {
            return "-"
        }
        return String(data: body, encoding: .utf8) ?? "-"
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
