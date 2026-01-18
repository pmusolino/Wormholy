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
    @State private var isShareSheetPresented = false
    @State private var selectedExportOption: RequestResponseExportOption = .flat

    var body: some View {
        List {
            Section("Overview") {
                Text(RequestModelBeautifier.overview(request: request).0)
                    .onTapGesture {
                        copyToClipboard(text: RequestModelBeautifier.overview(request: request).1)
                    }
            }

            Section("Request Header") {
                Text(RequestModelBeautifier.header(request.headers).0)
                    .onTapGesture {
                        copyToClipboard(text: RequestModelBeautifier.header(request.headers).1)
                    }
            }

            Section("Request Body") {
                if let httpBody = request.httpBody {
                    NavigationLink("View body") {
                        BodyDetailView(dataBody: httpBody)
                    }
                } else {
                    Text("No body available")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Response Header") {
                Text(RequestModelBeautifier.header(request.responseHeaders).0)
                    .onTapGesture {
                        copyToClipboard(text: RequestModelBeautifier.header(request.responseHeaders).1)
                    }
            }

            Section("Response Body") {
                if let dataResponse = request.dataResponse {
                    NavigationLink("View body") {
                        BodyDetailView(dataBody: dataResponse)
                    }
                } else {
                    Text("No body available")
                        .foregroundStyle(.secondary)
                }
            }

            if let errorDescription = request.errorClientDescription {
                Section("Error") {
                    Text("**Error**: \(errorDescription)")
                        .foregroundColor(.red)
                        .onTapGesture {
                            copyToClipboard(text: errorDescription)
                        }
                }
            }
        }
        .textSelection(.enabled)
        .listStyle(.insetGrouped)
        .navigationTitle(URL(string: request.url)?.path ?? "Request Detail")
        .inlineToolbarTitle()
        .toolbarBackground(.thinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Share", systemImage: "square.and.arrow.up") {
                        presentShareSheet(with: .flat)
                    }
                    Button("Share as cURL", systemImage: "terminal") {
                        presentShareSheet(with: .curl)
                    }
                    Button("Share as Postman", systemImage: "shippingbox") {
                        presentShareSheet(with: .postman)
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isShareSheetPresented) {
            ShareUtils.shareRequests(requests: [request], requestExportOption: selectedExportOption)
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }

    private func presentShareSheet(with option: RequestResponseExportOption) {
        selectedExportOption = option
        isShareSheetPresented = true
    }
    
    private func copyToClipboard(text: String) {
        UIPasteboard.general.string = text
        alertMessage = "Copied to clipboard"
        showAlert = true
    }
}

private struct InlineToolbarTitle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17, *) {
            content.toolbarTitleDisplayMode(.inline)
        } else {
            content
        }
    }
}

private extension View {
    func inlineToolbarTitle() -> some View {
        modifier(InlineToolbarTitle())
    }
}

struct RequestDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a fake request for preview
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
        
        // Create a fake request with an error for preview
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
