//
//  HighlightedTextView.swift
//  Wormholy
//
//  Created by Paolo Musolino on 29/11/24.
//

import SwiftUI

/// A UIViewRepresentable struct that wraps a UITextView to display and highlight text efficiently.
/// Used in BodyDetailView to handle long text with search functionality, highlighting search results.
internal struct HighlightedTextView: UIViewRepresentable {
    let text: String
    @Binding var highlightedRanges: [NSTextCheckingResult]
    @Binding var currentPosition: Int
    
    func makeUIView(context: Context) -> WHTextView {
        let textView = WHTextView()
        textView.isEditable = false
        textView.isSelectable = true
        return textView
    }
    
    func updateUIView(_ uiView: WHTextView, context: Context) {
        let attributedText = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: attributedText.length)
        
        // Set the font size to 16 for the entire text
        attributedText.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: fullRange)
        
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
                    let padding: CGFloat = 32
                    if visibleRect.maxY > (uiView.frame.height - keyboardHeight - padding) {
                        uiView.setContentOffset(CGPoint(x: 0, y: rect.origin.y - padding), animated: true)
                    }
                }
            }
        }
    }
}
