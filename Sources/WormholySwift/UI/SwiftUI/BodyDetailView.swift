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
    @State private var currentPosition: Int? = nil
    @State private var positionProxy: [Int: UUID] = [:]
    @State private var positionProxyForID: [UUID: [Int]] = [:]
    @State private var count: Int = 0
    var dataBody: Data?

    var body: some View {
        VStack {
            SearchBar(text: $searchText, onTextChanged: {
                if let dataBody = dataBody, let bodyString = String(data: dataBody, encoding: .utf8) {
                    DispatchQueue.global(qos: .userInitiated).async {
                        performSearch(text: searchText, in: bodyString)
                    }
                }
            })
            .padding(8)
            
            if let dataBody = dataBody, let bodyString = String(data: dataBody, encoding: .utf8) {
                ScrollViewReader { proxy in
                    HighlightedTextEditor(text: bodyString, highlightedRanges: highlightedRanges, currentPosition: currentPosition, positionProxyForID: positionProxyForID)
                        .padding(8)
                        .background(Color(UIColor.systemBackground))
                        .frame(maxHeight: .infinity)
                        .overlay(
                            VStack {
                                Spacer()
                                HStack {
                                    Button(action: {
                                        gotoPrevious()
                                    }) {
                                        Image(systemName: "chevron.up")
                                    }
                                    .disabled(currentPosition == nil)
                                    
                                    Button(action: {
                                        gotoNext()
                                    }) {
                                        Image(systemName: "chevron.down")
                                    }
                                    .disabled(currentPosition == nil)
                                    
                                    Spacer()
                                    
                                    if let currentPosition = currentPosition {
                                        Text("\(currentPosition + 1) of \(count)")
                                            .font(.footnote)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.systemBackground).opacity(0.9))
                            }
                        )
                        .onChange(of: currentPosition) { [lastID = currentID] _ in
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
                    .padding(8)
            }
        }
        .navigationTitle("Response Body")
    }
    
    private func performSearch(text: String, in bodyString: String) {
        highlightedRanges = [:]
        positionProxy = [:]
        positionProxyForID = [:]
        count = 0
        currentPosition = nil
        
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
            currentPosition = count > 0 ? 0 : nil
        }
    }
    
    private func gotoPrevious() {
        if let currentPosition, currentPosition > 0 {
            self.currentPosition = currentPosition - 1
        }
    }
    
    private func gotoNext() {
        if let currentPosition, currentPosition < count - 1 {
            self.currentPosition = currentPosition + 1
        }
    }
    
    private var currentID: UUID? {
        guard let currentPosition else { return nil }
        return positionProxy[currentPosition]
    }
}

struct TranscriptionRange {
    let position: Int
    let range: Range<String.Index>
}

struct HighlightedTextEditor: View {
    let text: String
    let highlightedRanges: [UUID: [TranscriptionRange]]
    let currentPosition: Int?
    let positionProxyForID: [UUID: [Int]]
    
    var body: some View {
        ScrollView {
            buildHighlightedText()
                .padding(8)
        }
    }
    
    private func buildHighlightedText() -> Text {
        var attributedText = AttributedString(text)
        
        for (id, ranges) in highlightedRanges {
            for transcriptionRange in ranges {
                if let lowerBound = AttributedString.Index(transcriptionRange.range.lowerBound, within: attributedText),
                   let upperBound = AttributedString.Index(transcriptionRange.range.upperBound, within: attributedText) {
                    
                    if currentPosition == transcriptionRange.position {
                        attributedText[lowerBound..<upperBound].swiftUI.backgroundColor = .yellow
                    } else {
                        attributedText[lowerBound..<upperBound].swiftUI.backgroundColor = .gray
                    }
                    attributedText[lowerBound..<upperBound].swiftUI.foregroundColor = .primary
                    
                    let positionScheme = "goPosition"
                    attributedText[lowerBound..<upperBound].link = URL(string: "\(positionScheme)://\(transcriptionRange.position)")
                }
            }
        }
        
        return Text(attributedText)
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
