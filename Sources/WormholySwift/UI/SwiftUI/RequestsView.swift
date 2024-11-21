//
//  RequestsView.swift
//  Wormholy
//
//  Created by Paolo Musolino on 20/11/24.
//

import SwiftUI

struct RequestsView: View {
    @State private var searchText = Storage.defaultFilter ?? ""
    @ObservedObject private var storage = Storage.shared
    @State private var filteredRequests: [RequestModel]
    @Environment(\.presentationMode) var presentationMode

    init(requests: [RequestModel] = Storage.shared.requests) {
        _filteredRequests = State(initialValue: requests)
        if let defaultFilter = Storage.defaultFilter, !defaultFilter.isEmpty {
            _searchText = State(initialValue: defaultFilter)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBar(text: $searchText, onSearchButtonClicked: filterRequests)
                List {
                    ForEach(filteredRequests, id: \.id) { request in
                            NavigationLink(destination: RequestDetailView(request: request)) {
                                RequestCellView(request: request)
                                    .padding(.all, 8)
                                    .frame(height: 76)
                                    
                            }
                        .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                    }
                }
                .listStyle(PlainListStyle())
                .navigationTitle("Requests")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("More") {
                            openActionSheet()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }
        .onReceive(storage.$requests) { _ in
            filterRequests()
        }
    }
    
    private func filterRequests() {
        if searchText.isEmpty {
            filteredRequests = storage.requests
        } else {
            filteredRequests = storage.requests.filter { request in
                request.url.range(of: searchText, options: .caseInsensitive) != nil
            }
        }
    }

    private func openActionSheet() {
        // TODO: Implement action sheet presentation
    }
}

struct RequestsView_Previews: PreviewProvider {
    static var previews: some View {
        // Create fake data for preview using the mock initializer with all parameters
        let fakeRequests = [
            RequestModel(
                id: UUID().uuidString,
                url: "https://example.com/api/v1/resources/items/12345/details?include=all&expand=full",
                host: "example.com",
                port: 443,
                scheme: "https",
                date: Date(),
                method: "GET",
                headers: ["Content-Type": "application/json"],
                credentials: ["user": "password"],
                cookies: "sessionid=abc123;",
                httpBody: nil,
                code: 200,
                responseHeaders: ["Content-Type": "application/json"],
                dataResponse: nil,
                errorClientDescription: nil,
                duration: 1.23
            ),
            RequestModel(
                id: UUID().uuidString,
                url: "https://example.com/api/v2/resources/items/67890/details?include=summary&expand=none&additional=parameters&to=make&url=longer&for=testing&purposes=only&this=is&a=very&long=url&that=should&be=twice&as=long&as=the&original",
                host: "example.com",
                port: 443,
                scheme: "https",
                date: Date(),
                method: "POST",
                headers: ["Content-Type": "application/json"],
                credentials: ["user": "password"],
                cookies: "sessionid=def456;",
                httpBody: nil,
                code: 401,
                responseHeaders: ["Content-Type": "application/json"],
                dataResponse: nil,
                errorClientDescription: nil,
                duration: 2.34
            )
        ]
        // Inject fake data into RequestsView
        return RequestsView(requests: fakeRequests)
    }
}
