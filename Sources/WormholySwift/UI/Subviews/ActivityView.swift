//
//  ActivityView.swift
//  Wormholy
//
//  Created by Paolo Musolino on 29/11/24.
//

import SwiftUI

// This view acts as a bridge to present a UIActivityViewController, allowing users to share content.
internal struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityView>) {}
}
