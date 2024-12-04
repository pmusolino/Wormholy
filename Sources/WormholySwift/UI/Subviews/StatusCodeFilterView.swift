//
//  StatusCodeFilterView.swift
//  Wormholy
//
//  Created by Paolo Musolino on 04/12/24.
//

import SwiftUI

internal struct StatusCodeFilterView: View {
    @Binding var selectedStatusCodeRange: ClosedRange<Int>?
    var onFilterChange: () -> Void

    var body: some View {
        HStack {
            Text("Filter")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.trailing, 8)
            
            Button(action: { toggleStatusCodeRange(100...199) }) {
                Text("1xx")
                    .foregroundColor(selectedStatusCodeRange == 100...199 ? .white : Colors.HTTPCode.Generic)
                    .padding(4)
                    .background(RoundedRectangle(cornerRadius: 6)
                    .fill(selectedStatusCodeRange == 100...199 ? Colors.HTTPCode.Generic : .clear))
                    .overlay(RoundedRectangle(cornerRadius: 6)
                    .stroke(Colors.HTTPCode.Generic, lineWidth: 1))
            }
            Button(action: { toggleStatusCodeRange(200...299) }) {
                Text("2xx")
                    .foregroundColor(selectedStatusCodeRange == 200...299 ? .white : Colors.HTTPCode.Success)
                    .padding(4)
                    .background(RoundedRectangle(cornerRadius: 6)
                    .fill(selectedStatusCodeRange == 200...299 ? Colors.HTTPCode.Success : .clear))
                    .overlay(RoundedRectangle(cornerRadius: 6)
                    .stroke(Colors.HTTPCode.Success, lineWidth: 1))
            }
            Button(action: { toggleStatusCodeRange(300...399) }) {
                Text("3xx")
                    .foregroundColor(selectedStatusCodeRange == 300...399 ? .white : Colors.HTTPCode.Redirect)
                    .padding(4)
                    .background(RoundedRectangle(cornerRadius: 6)
                    .fill(selectedStatusCodeRange == 300...399 ? Colors.HTTPCode.Redirect : .clear))
                    .overlay(RoundedRectangle(cornerRadius: 6)
                    .stroke(Colors.HTTPCode.Redirect, lineWidth: 1))
            }
            Button(action: { toggleStatusCodeRange(400...499) }) {
                Text("4xx")
                    .foregroundColor(selectedStatusCodeRange == 400...499 ? .white : Colors.HTTPCode.ClientError)
                    .padding(4)
                    .background(RoundedRectangle(cornerRadius: 6)
                    .fill(selectedStatusCodeRange == 400...499 ? Colors.HTTPCode.ClientError : .clear))
                    .overlay(RoundedRectangle(cornerRadius: 6)
                    .stroke(Colors.HTTPCode.ClientError, lineWidth: 1))
            }
            Button(action: { toggleStatusCodeRange(500...599) }) {
                Text("5xx")
                    .foregroundColor(selectedStatusCodeRange == 500...599 ? .white : Colors.HTTPCode.ServerError)
                    .padding(4)
                    .background(RoundedRectangle(cornerRadius: 6)
                    .fill(selectedStatusCodeRange == 500...599 ? Colors.HTTPCode.ServerError : .clear))
                    .overlay(RoundedRectangle(cornerRadius: 6)
                    .stroke(Colors.HTTPCode.ServerError, lineWidth: 1))
            }
        }
        .padding()
    }
    
    private func toggleStatusCodeRange(_ range: ClosedRange<Int>) {
        if selectedStatusCodeRange == range {
            selectedStatusCodeRange = nil
        } else {
            selectedStatusCodeRange = range
        }
        onFilterChange()
    }
}
