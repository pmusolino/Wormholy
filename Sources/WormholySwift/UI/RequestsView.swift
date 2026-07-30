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
    @State private var mode: TrafficMode = .requests
    @State private var filteredRequests: [RequestModel] = []
    @State private var filteredConnections: [WebSocketModel] = []
    @State private var shareSheetPayload: ShareSheetPayload?
    @State private var showStatsSheet = false
    @State private var showClearConfirmation = false
    @State private var selectedStatusCodeRange: ClosedRange<Int>?
    @Environment(\.dismiss) private var dismiss

    init(requests: [RequestModel] = [], webSocketConnections: [WebSocketModel] = []) {
        _filteredRequests = State(initialValue: requests)
        _filteredConnections = State(initialValue: webSocketConnections)
        if let defaultFilter = Storage.defaultFilter, !defaultFilter.isEmpty {
            _searchText = State(initialValue: defaultFilter)
        }
    }

    var body: some View {
        NavigationStack {
            listContent
                .navigationTitle(mode.title)
                .navigationBarTitleDisplayMode(.large)
                .searchable(text: $searchText, prompt: Text("Filter by URL"))
                .toolbar { toolbarContent }
        }
        .sheet(item: $shareSheetPayload) { payload in
            payload.activityView
        }
        .sheet(isPresented: $showStatsSheet) {
            StatsView()
        }
        .confirmationDialog(clearConfirmationTitle, isPresented: $showClearConfirmation, titleVisibility: .visible) {
            Button("Clear All", role: .destructive) { clearCurrentMode() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(clearConfirmationMessage)
        }
        .onAppear(perform: applyFilters)
        .onChange(of: storage.requests, perform: { _ in applyFilters() })
        .onChange(of: storage.webSocketConnections, perform: { _ in applyFilters() })
        .onChange(of: searchText, perform: { _ in applyFilters() })
        .onChange(of: selectedStatusCodeRange, perform: { _ in applyFilters() })
        .onChange(of: mode, perform: { _ in applyFilters() })
    }

    @ViewBuilder
    private var listContent: some View {
        switch mode {
        case .requests:
            List {
                topControlsSection(showStatusFilter: !storage.requests.isEmpty)

                if filteredRequests.isEmpty {
                    Text(emptyStateText(for: .requests))
                        .foregroundStyle(.secondary)
                } else {
                    Section {
                        ForEach(filteredRequests, id: \.id) { request in
                            NavigationLink(destination: RequestDetailView(request: request)) {
                                RequestCellView(request: request)
                                    .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.visible)
        case .webSockets:
            List {
                topControlsSection(showStatusFilter: false)

                if filteredConnections.isEmpty {
                    Text(emptyStateText(for: .webSockets))
                        .foregroundStyle(.secondary)
                } else {
                    Section {
                        ForEach(filteredConnections, id: \.id) { connection in
                            NavigationLink(destination: WebSocketDetailView(connection: connection)) {
                                WebSocketCellView(connection: connection)
                                    .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.visible)
        }
    }

    private func topControlsSection(showStatusFilter: Bool) -> some View {
        Section {
            trafficModeButtons
                .padding(.vertical, 2)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: showStatusFilter ? 2 : 8, trailing: 16))
                .listRowBackground(Color.clear)

            if showStatusFilter {
                StatusCodeFilterView(selectedStatusCodeRange: $selectedStatusCodeRange)
                    .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 8, trailing: 8))
                    .listRowBackground(Color.clear)
            }
        }
    }

    private var trafficModeButtons: some View {
        HStack(spacing: 8) {
            ForEach(TrafficMode.allCases, id: \.self) { item in
                Button {
                    mode = item
                } label: {
                    TrafficModeButton(mode: item,
                                      isSelected: mode == item,
                                      count: count(for: item))
                }
                .buttonStyle(.plain)
            }
        }
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
                switch mode {
                case .requests:
                    Button("Share filtered", systemImage: "square.and.arrow.up") {
                        presentShareSheet(with: .flat, requests: filteredRequests)
                    }
                    .disabled(filteredRequests.isEmpty)
                    Button("Share filtered as cURL", systemImage: "terminal") {
                        presentShareSheet(with: .curl, requests: filteredRequests)
                    }
                    .disabled(filteredRequests.isEmpty)
                    Button("Share filtered as Postman", systemImage: "shippingbox") {
                        presentShareSheet(with: .postman, requests: filteredRequests)
                    }
                    .disabled(filteredRequests.isEmpty)
                case .webSockets:
                    Button("Share filtered", systemImage: "square.and.arrow.up") {
                        presentShareSheet(connections: filteredConnections)
                    }
                    .disabled(filteredConnections.isEmpty)
                }
                Divider()
                Button(role: .destructive) {
                    showClearConfirmation = true
                } label: {
                    Label(mode == .requests ? "Clear requests" : "Clear connections", systemImage: "trash")
                }
            } label: {
                Label("More", systemImage: "ellipsis.circle")
            }
        }
    }

    private var clearConfirmationTitle: String {
        mode == .requests ? "Clear captured requests?" : "Clear captured connections?"
    }

    private var clearConfirmationMessage: String {
        mode == .requests
            ? "This removes the currently stored network calls from Wormholy."
            : "This removes the currently stored WebSocket connections from Wormholy."
    }

    private func applyFilters() {
        filteredRequests = storage.requests.filter { request in
            let matchesSearchText = searchText.isEmpty
                || request.url.range(of: searchText, options: .caseInsensitive) != nil
            let matchesStatusCode = selectedStatusCodeRange.map { $0.contains(request.code) } ?? true
            return matchesSearchText && matchesStatusCode
        }
        filteredConnections = storage.webSocketConnections.filter { connection in
            searchText.isEmpty || connection.url.range(of: searchText, options: .caseInsensitive) != nil
        }
    }

    private func clearCurrentMode() {
        switch mode {
        case .requests:
            storage.clearRequests()
        case .webSockets:
            storage.clearWebSocketConnections()
        }
        applyFilters()
    }

    private func emptyStateText(for mode: TrafficMode) -> String {
        if isFiltering {
            return "No results."
        }

        switch mode {
        case .requests:
            return storage.requests.isEmpty ? "No requests captured yet." : "No results."
        case .webSockets:
            return storage.webSocketConnections.isEmpty ? "No WebSocket connections captured yet." : "No results."
        }
    }

    private var isFiltering: Bool {
        !searchText.isEmpty || selectedStatusCodeRange != nil
    }

    private func presentShareSheet(with option: RequestResponseExportOption, requests: [RequestModel]) {
        shareSheetPayload = ShareSheetPayload(content: .requests(requests, option))
    }

    private func presentShareSheet(connections: [WebSocketModel]) {
        shareSheetPayload = ShareSheetPayload(content: .webSockets(connections))
    }

    private func count(for mode: TrafficMode) -> Int {
        switch mode {
        case .requests:
            return storage.requests.count
        case .webSockets:
            return storage.webSocketConnections.count
        }
    }
}

private struct ShareSheetPayload: Identifiable {
    let id = UUID()
    let content: Content

    @MainActor
    var activityView: ActivityView {
        switch content {
        case let .requests(requests, exportOption):
            return ShareUtils.shareRequests(requests: requests, requestExportOption: exportOption)
        case let .webSockets(connections):
            return ShareUtils.shareWebSockets(connections: connections)
        }
    }

    enum Content {
        case requests([RequestModel], RequestResponseExportOption)
        case webSockets([WebSocketModel])
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
                url: "https://example.com/api/v2/resources/items/67890/details?"
                    + "include=summary&expand=none&additional=parameters&to=make&url=longer&"
                    + "for=testing&purposes=only&this=is&a=very&long=url&that=should&be=twice&"
                    + "as=long&as=the&original",
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

        let connectionStartedAt = Date(timeIntervalSinceNow: -90)
        let fakeConnection = WebSocketModel(url: "wss://ws.postman-echo.com/raw", startDate: connectionStartedAt)
        fakeConnection.markOpened(at: connectionStartedAt.addingTimeInterval(2))
        fakeConnection.addMessage(direction: .sent,
                                  message: .string("hello"),
                                  at: connectionStartedAt.addingTimeInterval(12))

        return RequestsView(requests: fakeRequests, webSocketConnections: [fakeConnection])
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
