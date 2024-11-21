//
//  BodyDetailView.swift
//  Wormholy
//
//  Created by Paolo Musolino on 21/11/24.
//

import SwiftUI

struct BodyDetailView: View {
    var dataBody: Data?

    var body: some View {
        ScrollView {
            if let dataBody = dataBody, let bodyString = String(data: dataBody, encoding: .utf8) {
                Text(bodyString)
                    .padding()
            } else {
                Text("No body available")
                    .padding()
            }
        }
        .navigationTitle("Body Detail")
    }
}
