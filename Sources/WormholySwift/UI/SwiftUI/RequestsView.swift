//
//  RequestsView.swift
//  Wormholy
//
//  Created by Paolo Musolino on 20/11/24.
//

import SwiftUI

struct RequestsView: View {
    @State private var searchText = ""
    @State private var filteredRequests: [RequestModel]
    
    init(requests: [RequestModel] = Storage.shared.requests) {
        _filteredRequests = State(initialValue: requests)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText, onSearchButtonClicked: filterRequests)
                List {
                    ForEach(filteredRequests, id: \.self) { request in
                        VStack(spacing: 0) {
                            RequestCellView(request: request)
                                .frame(height: 80)
                                .onTapGesture {
                                    openRequestDetail(request: request)
                                }
                                .padding(.all, 8)

                            // Separator    
                            Rectangle()
                                .fill(Color.gray)
                                .frame( height: 8)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
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
                            dismissView()
                        }
                    }
                }
            }
        }
        .onAppear {
            NotificationCenter.default.addObserver(forName: newRequestNotification, object: nil, queue: nil) { _ in
                filterRequests()
            }
        }
    }
    
    private func filterRequests() {
        if searchText.isEmpty {
            filteredRequests = Storage.shared.requests
        } else {
            filteredRequests = Storage.shared.requests.filter { request in
                request.url.range(of: searchText, options: .caseInsensitive) != nil
            }
        }
    }
    
    private func openRequestDetail(request: RequestModel) {
        // Implement navigation to request detail view
    }
    
    private func openActionSheet() {
        // Implement action sheet presentation
    }
    
    private func dismissView() {
        // Implement view dismissal
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

struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    var onSearchButtonClicked: () -> Void

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String
        var onSearchButtonClicked: () -> Void

        init(text: Binding<String>, onSearchButtonClicked: @escaping () -> Void) {
            _text = text
            self.onSearchButtonClicked = onSearchButtonClicked
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            onSearchButtonClicked()
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, onSearchButtonClicked: onSearchButtonClicked)
    }

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.placeholder = "Search URL"
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
}

struct RequestCellView: View {
    var request: RequestModel

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                Text(request.method.uppercased())
                    .font(.headline)
                
                if request.code != 0 {
                    Text("\(request.code)")
                        .font(.caption)
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 6)
                                        .stroke(getCodeColor(code: request.code), lineWidth: 0.5))
                        .foregroundColor(getCodeColor(code: request.code))
                }
                
                if let duration = request.duration {
                    Text(duration.formattedMilliseconds())
                        .font(.subheadline)
                }
            }
            .frame(width: 50, height: 80, alignment: .leading)
            .padding(.leading, 8)
            
            
            Text(request.url)
                .font(.body)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .padding([.leading, .trailing], 16)
        }
    }
    
    private func getCodeColor(code: Int) -> Color {
        switch code {
        case 200..<300:
            return Color(Colors.HTTPCode.Success)
        case 300..<400:
            return Color(Colors.HTTPCode.Redirect)
        case 400..<500:
            return Color(Colors.HTTPCode.ClientError)
        case 500..<600:
            return Color(Colors.HTTPCode.ServerError)
        default:
            return Color(Colors.HTTPCode.Generic)
        }
    }
}
