//
//  RequestsView.swift
//  Wormholy
//
//  Created by Paolo Musolino on 20/11/24.
//

import SwiftUI

internal struct RequestsView: View {
    @State private var searchText = Storage.defaultFilter ?? ""
    @ObservedObject private var storage = Storage.shared
    @State private var filteredRequests: [RequestModel] = []
    @Environment(\.presentationMode) var presentationMode
    @State private var isActionSheetPresented = false
    @State private var isShareSheetPresented = false
    @State private var isStatsViewPresented = false
    @State private var selectedExportOption: RequestResponseExportOption = .flat
    @State private var selectedStatusCodeRange: ClosedRange<Int>? // Range of status codes for filtering requests

    init(requests: [RequestModel] = []) {
        _filteredRequests = State(initialValue: requests)
        if let defaultFilter = Storage.defaultFilter, !defaultFilter.isEmpty {
            _searchText = State(initialValue: defaultFilter)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBar(text: $searchText, onTextChanged: filterRequests)
                
                StatusCodeFilterView(selectedStatusCodeRange: $selectedStatusCodeRange, onFilterChange: filterRequests)
                Divider()

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
                .animation(.bouncy, value: filteredRequests)
                .listStyle(PlainListStyle())
                .navigationTitle("Requests")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("More") {
                            isActionSheetPresented = true
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                .actionSheet(isPresented: $isActionSheetPresented) {
                    ActionSheet(title: Text("Wormholy"), message: Text("Choose an option"), buttons: [
                        .default(Text("Clear")) {
                            clearRequests()
                        },
                        .default(Text("Stats")) {
                            isStatsViewPresented = true
                        },
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
                    ])
                }
                .sheet(isPresented: $isShareSheetPresented) {
                    // Using ShareUtils to create the ActivityView for sharing content
                    ShareUtils.shareRequests(requests: filteredRequests, requestExportOption: selectedExportOption)
                }
                .sheet(isPresented: $isStatsViewPresented) {
                    StatsView()
                }
            }
        }
        .onAppear {
            filterRequests() // Ensure requests are filtered on first load
        }
        .onReceive(storage.$requests) { _ in
            filterRequests()
        }
    }
    
    private func filterRequests() {
        filteredRequests = storage.requests.filter { request in
            let matchesSearchText = searchText.isEmpty || request.url.range(of: searchText, options: .caseInsensitive) != nil
            let matchesStatusCode = selectedStatusCodeRange == nil || selectedStatusCodeRange!.contains(request.code)
            return matchesSearchText && matchesStatusCode
        }
    }

    private func clearRequests() {
        // Clear the requests from storage.
        storage.clearRequests()
        filterRequests() // Ensure filteredRequests is updated after clearing
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
                startDate: Date(),
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
                startDate: Date(),
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
