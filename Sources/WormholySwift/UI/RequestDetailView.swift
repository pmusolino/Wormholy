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
    @State private var isActionSheetPresented = false
    @State private var isShareSheetPresented = false
    @State private var selectedExportOption: RequestResponseExportOption = .flat

    var body: some View {
        // Заменили NavigationStack на NavigationView:
        NavigationView {
            List {
                // MARK: - Overview Section
                Section(header: Text("Overview")) {
                    Text(RequestModelBeautifier.overview(request: request).0)
                        .onTapGesture {
                            // Копируем оригинальный текст
                            copyToClipboard(text: RequestModelBeautifier.overview(request: request).1)
                        }
                }
                
                // MARK: - Request Header Section
                Section(header: Text("Request Header")) {
                    Text(RequestModelBeautifier.header(request.headers).0)
                        .onTapGesture {
                            copyToClipboard(text: RequestModelBeautifier.header(request.headers).1)
                        }
                }
                
                // MARK: - Request Body Section
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
                
                // MARK: - Response Header Section
                Section(header: Text("Response Header")) {
                    Text(RequestModelBeautifier.header(request.responseHeaders).0)
                        .onTapGesture {
                            copyToClipboard(text: RequestModelBeautifier.header(request.responseHeaders).1)
                        }
                }
                
                // MARK: - Response Body Section
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
                
                // MARK: - Error Section
                if let errorDescription = request.errorClientDescription {
                    Section(header: Text("Error")) {
                        Text("**Error**: \(errorDescription)")
                            .foregroundColor(.red)
                            .onTapGesture {
                                copyToClipboard(text: errorDescription)
                            }
                    }
                }
            }
            .textSelection(.enabled)
            .listStyle(GroupedListStyle())
            .navigationTitle(URL(string: request.url)?.path ?? "Request Detail")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("More") {
                        isActionSheetPresented = true
                    }
                }
            }
            // MARK: - Action Sheet
            .actionSheet(isPresented: $isActionSheetPresented) {
                ActionSheet(
                    title: Text("Wormholy"),
                    message: Text("Choose an option"),
                    buttons: [
                        .default(Text("Share")) {
                            selectedExportOption = .flat
                            isShareSheetPresented = true
                        },
                        .default(Text("Share as cURL")) {
                            selectedExportOption = .curl
                            isShareSheetPresented = true
                        },
                        .default(Text("Share as Postman Collection")) {
                            selectedExportOption = .postman
                            isShareSheetPresented = true
                        },
                        .cancel()
                    ]
                )
            }
            // MARK: - Sheet для шаринга
            .sheet(isPresented: $isShareSheetPresented) {
                ShareUtils.shareRequests(requests: [request], requestExportOption: selectedExportOption)
            }
            // MARK: - Alert при копировании
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Copied"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Copy to Clipboard
    private func copyToClipboard(text: String) {
        UIPasteboard.general.string = text
        alertMessage = "Text copied to clipboard"
        showAlert = true
    }
}

// MARK: - Превью
struct RequestDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Пример запроса без ошибки
        let fakeRequest = RequestModel(
            id: UUID().uuidString,
            url: "https://example.com/api/v1/resources/items/12345/details?include=all&expand=full",
            host: "example.com",
            port: 443,
            scheme: "https",
            startDate: Date(),
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
        
        // Пример запроса с ошибкой
        let fakeErrorRequest = RequestModel(
            id: UUID().uuidString,
            url: "https://example.com/api/v1/resources/items/12345/details?include=all&expand=full",
            host: "example.com",
            port: 443,
            scheme: "https",
            startDate: Date(),
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
