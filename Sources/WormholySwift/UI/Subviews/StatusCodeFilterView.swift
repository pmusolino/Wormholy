//
//  StatusCodeFilterView.swift
//  Wormholy
//
//  Created by Paolo Musolino on 04/12/24.
//

import SwiftUI

internal struct StatusCodeFilterView: View {
    @Binding var selectedStatusCodeRange: ClosedRange<Int>?

    var body: some View {
        HStack(spacing: 8) {
            Text("Filter")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.trailing, 4)
            
            filterButton(for: 100...199, label: "1xx", color: Colors.HTTPCode.Generic)
            filterButton(for: 200...299, label: "2xx", color: Colors.HTTPCode.Success)
            filterButton(for: 300...399, label: "3xx", color: Colors.HTTPCode.Redirect)
            filterButton(for: 400...499, label: "4xx", color: Colors.HTTPCode.ClientError)
            filterButton(for: 500...599, label: "5xx", color: Colors.HTTPCode.ServerError)
        }
        .padding()
    }
    
    private func filterButton(for range: ClosedRange<Int>, label: String, color: Color) -> some View {
        let isSelected = selectedStatusCodeRange == range
        
        return Button(action: {
            toggleStatusCodeRange(range)
        }) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? color : .clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(color, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
    
    private func toggleStatusCodeRange(_ range: ClosedRange<Int>) {
        if selectedStatusCodeRange == range {
            selectedStatusCodeRange = nil
        } else {
            selectedStatusCodeRange = range
        }
    }
}
