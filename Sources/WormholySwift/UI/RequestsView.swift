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
    @State private var showShareSheet = false
    @State private var showStatsSheet = false
    @State private var showClearConfirmation = false
    @State private var selectedExportOption: RequestResponseExportOption = .flat
    @State private var selectedStatusCodeRange: ClosedRange<Int>?
    @State private var shareSourceRequests: [RequestModel] = []
    @Environment(\.dismiss) private var dismiss

    init(requests: [RequestModel] = []) {
        _filteredRequests = State(initialValue: requests)
        if let defaultFilter = Storage.defaultFilter, !defaultFilter.isEmpty {
            _searchText = State(initialValue: defaultFilter)
        }
    }

    var body: some View {
        NavigationStack {
            listContent
                .navigationTitle("Requests")
                .navigationBarTitleDisplayMode(.large)
                .searchable(text: $searchText, prompt: Text("Filter by URL"))
                .toolbar { toolbarContent }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareUtils.shareRequests(requests: shareSourceRequests, requestExportOption: selectedExportOption)
        }
        .sheet(isPresented: $showStatsSheet) {
            StatsView()
        }
        .confirmationDialog("Clear captured requests?", isPresented: $showClearConfirmation, titleVisibility: .visible) {
            Button("Clear All", role: .destructive) { clearRequests() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes the currently stored network calls from Wormholy.")
        }
        .onAppear(perform: applyFilters)
        .onChange(of: storage.requests, perform: { _ in applyFilters() })
        .onChange(of: searchText, perform: { _ in applyFilters() })
        .onChange(of: selectedStatusCodeRange, perform: { _ in applyFilters() })
    }

    @ViewBuilder
    private var listContent: some View {
        List {
            if !storage.requests.isEmpty {
                Section {
                    StatusCodeFilterView(selectedStatusCodeRange: $selectedStatusCodeRange)
                        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 4, trailing: 8))
                        .listRowBackground(Color.clear)
                }
            }

            Section {
                ForEach(filteredRequests, id: \.id) { request in
                    NavigationLink(destination: RequestDetailView(request: request)) {
                        RequestCellView(request: request)
                            .padding(.vertical, 8)
                            .frame(height: 76)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.visible)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Done") { dismiss() }
        }
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button("Stats", systemImage: "chart.bar") { showStatsSheet = true }
                Divider()
                Button("Share filtered", systemImage: "square.and.arrow.up") {
                    selectedExportOption = .flat
                    shareSourceRequests = filteredRequests
                    showShareSheet = true
                }
                .disabled(filteredRequests.isEmpty)
                Button("Share filtered as cURL", systemImage: "terminal") {
                    selectedExportOption = .curl
                    shareSourceRequests = filteredRequests
                    showShareSheet = true
                }
                .disabled(filteredRequests.isEmpty)
                Button("Share filtered as Postman", systemImage: "shippingbox") {
                    selectedExportOption = .postman
                    shareSourceRequests = filteredRequests
                    showShareSheet = true
                }
                .disabled(filteredRequests.isEmpty)
                Divider()
                Button(role: .destructive) {
                    showClearConfirmation = true
                } label: {
                    Label("Clear requests", systemImage: "trash")
                }
            } label: {
                Label("More", systemImage: "ellipsis.circle")
            }
        }
    }

    private func applyFilters() {
        filteredRequests = storage.requests.filter { request in
            let matchesSearchText = searchText.isEmpty || request.url.range(of: searchText, options: .caseInsensitive) != nil
            let matchesStatusCode = selectedStatusCodeRange.map { $0.contains(request.code) } ?? true
            return matchesSearchText && matchesStatusCode
        }
    }

    private func clearRequests() {
        storage.clearRequests()
        applyFilters()
    }

    private func shareSingleRequest(_ option: RequestResponseExportOption, _ request: RequestModel) {
        selectedExportOption = option
        shareSourceRequests = [request]
        showShareSheet = true
    }
}

struct RequestsView_Previews: PreviewProvider {
    static var previews: some View {
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

        return RequestsView(requests: fakeRequests)
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
