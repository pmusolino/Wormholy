//
//  BodyDetailView.swift
//  Wormholy
//
//  Created by Paolo Musolino on 21/11/24.
//

import SwiftUI

struct BodyDetailView: View {
    @State private var searchText: String = ""
    @State private var highlightedRanges: [UUID: [TranscriptionRange]] = [:]
    @State private var currentHighlightIndex: Int? = nil
    @State private var positionProxy: [Int: UUID] = [:]
    @State private var positionProxyForID: [UUID: [Int]] = [:]
    @State private var count: Int = 0
    @State private var isSearching: Bool = false
    var dataBody: Data?

    var body: some View {
        VStack {
            SearchBar(text: $searchText, onTextChanged: {
                if let dataBody = dataBody, let bodyString = String(data: dataBody, encoding: .utf8) {
                    isSearching = true
                    DispatchQueue.global(qos: .userInitiated).async {
                        performSearch(text: searchText, in: bodyString)
                        DispatchQueue.main.async {
                            isSearching = false
                        }
                    }
                }
            })
            .padding([.leading, .trailing])
            
            if let dataBody = dataBody, let bodyString = String(data: dataBody, encoding: .utf8) {
                ScrollViewReader { proxy in
                    HighlightedTextEditor(text: bodyString, highlightedRanges: highlightedRanges)
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .onAppear {
                            performSearch(text: searchText, in: bodyString)
                        }
                        .overlay(
                            VStack {
                                Spacer()
                                HStack {
                                    Button(action: {
                                        gotoPrevious()
                                    }) {
                                        Image(systemName: "chevron.up")
                                    }
                                    .disabled(currentHighlightIndex == nil || isSearching)
                                    
                                    Button(action: {
                                        gotoNext()
                                    }) {
                                        Image(systemName: "chevron.down")
                                    }
                                    .disabled(currentHighlightIndex == nil || isSearching)
                                    
                                    Spacer()
                                    
                                    if let currentHighlightIndex = currentHighlightIndex {
                                        Text("\(currentHighlightIndex + 1) of \(count)")
                                            .font(.footnote)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.systemBackground).opacity(0.9))
                            }
                        )
                        .onChange(of: currentHighlightIndex) { [lastID = currentID] _ in
                            let currentID = currentID
                            if lastID != currentID {
                                withAnimation {
                                    if let currentID = currentID {
                                        proxy.scrollTo(currentID, anchor: .center)
                                    }
                                }
                            }
                        }
                }
            } else {
                Text("No body available")
                    .padding()
            }
        }
        .navigationTitle("Body Detail")
    }
    
    private func performSearch(text: String, in bodyString: String) {
        highlightedRanges = [:]
        positionProxy = [:]
        positionProxyForID = [:]
        count = 0
        currentHighlightIndex = nil
        
        if !text.isEmpty {
            let regex = try! NSRegularExpression(pattern: NSRegularExpression.escapedPattern(for: text), options: [.caseInsensitive])
            let nsString = bodyString as NSString
            let matches = regex.matches(in: bodyString, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for (index, match) in matches.enumerated() {
                if let range = Range(match.range, in: bodyString) {
                    let transcriptionRange = TranscriptionRange(position: index, range: range)
                    let id = UUID()
                    highlightedRanges[id] = [transcriptionRange]
                    positionProxy[index] = id
                    positionProxyForID[id] = [index]
                }
            }
            
            count = matches.count
            currentHighlightIndex = count > 0 ? 0 : nil
        }
    }
    
    private func gotoPrevious() {
        if let currentHighlightIndex, currentHighlightIndex > 0 {
            self.currentHighlightIndex = currentHighlightIndex - 1
        }
    }
    
    private func gotoNext() {
        if let currentHighlightIndex, currentHighlightIndex < count - 1 {
            self.currentHighlightIndex = currentHighlightIndex + 1
        }
    }
    
    private var currentID: UUID? {
        guard let currentHighlightIndex else { return nil }
        return positionProxy[currentHighlightIndex]
    }
}

struct TranscriptionRange {
    let position: Int
    let range: Range<String.Index>
}

struct HighlightedTextEditor: View {
    let text: String
    let highlightedRanges: [UUID: [TranscriptionRange]]
    
    var body: some View {
        ScrollView {
            buildHighlightedText()
                .padding()
        }
    }
    
    private func buildHighlightedText() -> Text {
        var result = Text("")
        var currentIndex = text.startIndex
        
        for ranges in highlightedRanges.values {
            for transcriptionRange in ranges {
                let range = transcriptionRange.range
                if currentIndex < range.lowerBound {
                    result = result + Text(String(text[currentIndex..<range.lowerBound]))
                }
                result = result + Text(String(text[range]))
                    .foregroundColor(.blue) // Changed to blue for highlighting
                currentIndex = range.upperBound
            }
        }
        
        if currentIndex < text.endIndex {
            result = result + Text(String(text[currentIndex..<text.endIndex]))
        }
        
        return result
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
        
        return BodyDetailView(dataBody: sampleData)
            .previewDisplayName("Body Detail View")
    }
}
