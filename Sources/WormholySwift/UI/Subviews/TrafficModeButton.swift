// Copyright (c) 2026 Wormholy contributors
// SPDX-License-Identifier: MIT

import SwiftUI

internal enum TrafficMode: CaseIterable {
    case requests
    case webSockets

    var title: String {
        switch self {
        case .requests:
            return "Requests"
        case .webSockets:
            return "WebSockets"
        }
    }

    var icon: String {
        switch self {
        case .requests:
            return "arrow.left.arrow.right"
        case .webSockets:
            return "bolt.horizontal"
        }
    }
}

internal struct TrafficModeButton: View {
    let mode: TrafficMode
    let isSelected: Bool
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: mode.icon)
                .font(.footnote.weight(.semibold))
            Text(mode.title)
                .font(.footnote.weight(.semibold))
            Spacer(minLength: 4)
            Text("\(count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(isSelected ? .primary : .secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color(.secondarySystemGroupedBackground) : Color.clear)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color(.separator) : Color.clear, lineWidth: 0.5)
        }
        .accessibilityLabel(Text(mode.title))
        .accessibilityValue(Text(isSelected ? "Selected, \(count) items" : "\(count) items"))
    }
}

struct TrafficModeButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                TrafficModeButton(mode: .requests, isSelected: true, count: 20)
                TrafficModeButton(mode: .webSockets, isSelected: false, count: 1)
            }

            HStack(spacing: 8) {
                TrafficModeButton(mode: .requests, isSelected: false, count: 20)
                TrafficModeButton(mode: .webSockets, isSelected: true, count: 1)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .previewLayout(.sizeThatFits)
    }
}
