// Copyright (c) 2026 Wormholy contributors
// SPDX-License-Identifier: MIT

import SwiftUI

internal struct WebSocketCellView: View {
    @ObservedObject var connection: WebSocketModel

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(connection.state.title.uppercased())
                    .font(.caption)
                    .bold()
                    .padding(4)
                    .background(RoundedRectangle(cornerRadius: 6)
                                    .stroke(Colors.WebSocket.getStateColor(connection.state), lineWidth: 0.5))
                    .foregroundColor(Colors.WebSocket.getStateColor(connection.state))

                Text("\(connection.messages.count) msg")
                    .font(.footnote)
            }

            Text(connection.url)
                .font(.subheadline)
                .lineLimit(5)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct WebSocketCellView_Previews: PreviewProvider {
    static var previews: some View {
        let openConnectionStartedAt = Date(timeIntervalSinceNow: -120)
        let openConnection = WebSocketModel(url: "wss://ws.postman-echo.com/raw",
                                            startDate: openConnectionStartedAt)
        openConnection.markOpened(at: openConnectionStartedAt.addingTimeInterval(2))
        openConnection.addMessage(direction: .sent,
                                  message: .string("hello"),
                                  at: openConnectionStartedAt.addingTimeInterval(20))
        openConnection.addMessage(direction: .received,
                                  message: .string("hello back"),
                                  at: openConnectionStartedAt.addingTimeInterval(21))

        let closedConnectionStartedAt = Date(timeIntervalSinceNow: -180)
        let closedConnection = WebSocketModel(url: "wss://ws.postman-echo.com/raw/very/long/path/that/wraps",
                                              startDate: closedConnectionStartedAt)
        closedConnection.markOpened(at: closedConnectionStartedAt.addingTimeInterval(2))
        closedConnection.markClosed(code: .normalClosure,
                                    reason: nil,
                                    at: closedConnectionStartedAt.addingTimeInterval(30))

        return VStack(alignment: .leading, spacing: 12) {
            WebSocketCellView(connection: openConnection)
            WebSocketCellView(connection: closedConnection)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
