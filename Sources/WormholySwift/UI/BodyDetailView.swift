//
//  BodyDetailView.swift
//  Wormholy
//
//  Created by Paolo Musolino on 21/11/24.
//

import SwiftUI
import UIKit

internal struct BodyDetailView: View {
    @State private var searchText: String = ""
    @State private var highlightedRanges: [NSTextCheckingResult] = []
    @State private var currentPosition: Int = 0
    @State private var isShareSheetPresented: Bool = false
    private let dataBody: String
    
    init(dataBody: Data) {
        self.dataBody = String(data: dataBody, encoding: .utf8) ?? "No body available"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBar(text: $searchText, onTextChanged: {
                performSearch(text: searchText)
            })
            .padding([.top, .leading, .trailing], 8)
            
            // Using HighlightedTextView, a UIViewRepresentable wrapper for UITextView, to handle long text efficiently.
            HighlightedTextView(text: dataBody, highlightedRanges: $highlightedRanges, currentPosition: $currentPosition)
                .padding([.bottom, .leading, .trailing], 8)
                .background(Color(UIColor.systemBackground))
                .frame(maxHeight: .infinity)
            
            // The bar with chevron up and down
            HStack {
                Button(action: {
                    gotoPrevious()
                }) {
                    Image(systemName: "chevron.up")
                }
                .disabled(highlightedRanges.isEmpty)
                
                Button(action: {
                    gotoNext()
                }) {
                    Image(systemName: "chevron.down")
                }
                .disabled(highlightedRanges.isEmpty)
                
                Spacer()
                
                if !highlightedRanges.isEmpty {
                    Text("\(currentPosition + 1) of \(highlightedRanges.count)")
                        .font(.body)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground).opacity(0.9))
        }
        .navigationTitle("Response Body")
        .navigationBarItems(trailing: Button(action: {
            isShareSheetPresented = true
        }) {
            Image(systemName: "square.and.arrow.up")
        })
        .sheet(isPresented: $isShareSheetPresented, content: {
            ActivityView(activityItems: [dataBody])
        })
    }
    
    private func performSearch(text: String) {
        highlightedRanges = []
        currentPosition = 0
        
        if !text.isEmpty {
            let regex = try! NSRegularExpression(pattern: NSRegularExpression.escapedPattern(for: text), options: [.caseInsensitive])
            let nsString = dataBody as NSString
            highlightedRanges = regex.matches(in: dataBody, options: [], range: NSRange(location: 0, length: nsString.length))
        }
    }
    
    private func gotoPrevious() {
        if currentPosition > 0 {
            currentPosition -= 1
        }
    }
    
    private func gotoNext() {
        if currentPosition < highlightedRanges.count - 1 {
            currentPosition += 1
        }
    }
}

struct BodyDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleData = """
        {
            "key1": "value1",
            "key2": "value2",
            "key3": "value3"
        }
        """.data(using: .utf8)
        
        return BodyDetailView(dataBody: sampleData!)
            .previewDisplayName("Body Detail View")
    }
}
