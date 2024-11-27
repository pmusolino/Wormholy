//
//  BodyDetailView.swift
//  Wormholy
//
//  Created by Paolo Musolino on 21/11/24.
//

import SwiftUI
import UIKit

struct BodyDetailView: View {
    @State private var searchText: String = ""
    @State private var highlightedRanges: [NSTextCheckingResult] = []
    @State private var currentPosition: Int = 0
    private let dataBody: String
    
    init(dataBody: Data) {
        self.dataBody = String(data: dataBody, encoding: .utf8) ?? "No body available"
    }
    
    var body: some View {
        VStack {
            SearchBar(text: $searchText, onTextChanged: {
                performSearch(text: searchText)
            })
            .padding(8)
            
            // Using HighlightedTextView, a UIViewRepresentable wrapper for UITextView, to handle long text efficiently.
            HighlightedTextView(text: dataBody, highlightedRanges: $highlightedRanges, currentPosition: $currentPosition)
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
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground).opacity(0.9))
                    }
                )
        }
        .navigationTitle("Response Body")
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

struct HighlightedTextView: UIViewRepresentable {
    let text: String
    @Binding var highlightedRanges: [NSTextCheckingResult]
    @Binding var currentPosition: Int
    
    func makeUIView(context: Context) -> WHTextView {
        let textView = WHTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = UIFont.systemFont(ofSize: 14)
        return textView
    }
    
    func updateUIView(_ uiView: WHTextView, context: Context) {
        uiView.text = text
        let attributedText = NSMutableAttributedString(string: text)
        
        for (index, match) in highlightedRanges.enumerated() {
            let color: UIColor = (index == currentPosition) ? .yellow : .gray
            attributedText.addAttribute(.backgroundColor, value: color, range: match.range)
        }
        
        uiView.attributedText = attributedText
        
        if !highlightedRanges.isEmpty {
            let currentRange = highlightedRanges[currentPosition].range
            if let textRange = uiView.convertRange(range: currentRange) {
                uiView.scrollRangeToVisible(currentRange)
                uiView.selectedTextRange = textRange
                
                // Ensure padding between highlighted text and keyboard
                DispatchQueue.main.async {
                    let rect = uiView.firstRect(for: textRange)
                    let visibleRect = uiView.convert(rect, to: uiView.superview)
                    let keyboardHeight: CGFloat = 300 // Approximate keyboard height
                    let padding: CGFloat = 16
                    if visibleRect.maxY > (uiView.frame.height - keyboardHeight - padding) {
                        uiView.setContentOffset(CGPoint(x: 0, y: rect.origin.y - padding), animated: true)
                    }
                }
            }
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
