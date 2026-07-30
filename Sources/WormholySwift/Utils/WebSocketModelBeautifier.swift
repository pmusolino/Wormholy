// Copyright (c) 2026 Wormholy contributors
// SPDX-License-Identifier: MIT

import Foundation
import SwiftUI

@MainActor
internal enum WebSocketModelBeautifier {
    private static let previewContentLimit = 160
    private static let binaryPreviewByteLimit = 80

    static func overview(connection: WebSocketModel) -> (LocalizedStringKey, String) {
        var lines = [
            "**URL:** \(connection.url)",
            "**Method:** GET",
            "**State:** \(connection.state.title)",
            "**Start Time:** \(formatDate(connection.startDate))",
            "**Opened Time:** \(formatDate(connection.openedAt))",
            "**Closed Time:** \(formatDate(connection.closedAt))",
            "**Duration:** \(duration(connection))",
            "**Sent Messages:** \(connection.sentMessageCount)",
            "**Received Messages:** \(connection.receivedMessageCount)",
            "**Total Messages:** \(connection.messages.count)"
        ]

        if !connection.requestedProtocols.isEmpty {
            lines.append("**Requested Protocols:** \(connection.requestedProtocols.joined(separator: ", "))")
        }
        if let negotiatedProtocol = connection.negotiatedProtocol {
            lines.append("**Negotiated Protocol:** \(negotiatedProtocol)")
        }
        if let closeCode = connection.closeCode {
            lines.append("**Close Code:** \(closeCode.rawValue)")
        }
        if let closeReason = connection.closeReason {
            lines.append("**Close Reason:** \(closeReason)")
        }

        let combinedString = lines.joined(separator: "\n")
        return (LocalizedStringKey(combinedString), combinedString)
    }

    static func header(_ headers: [String: String]) -> (LocalizedStringKey, String) {
        guard !headers.isEmpty else {
            return (LocalizedStringKey("-"), "-")
        }

        let combinedString = headers
            .sorted { $0.key < $1.key }
            .map { "**\($0.key):** \($0.value)" }
            .joined(separator: "\n")
        return (LocalizedStringKey(combinedString), combinedString)
    }

    static func messagePreview(_ message: WebSocketMessage) -> String {
        switch message.message {
        case .string(let text):
            return formattedText(text, maximumLength: previewContentLimit)
        case .data(let data):
            return binaryBodyText(data, maximumByteCount: binaryPreviewByteLimit)
        @unknown default:
            return "<unknown message type>"
        }
    }

    static func bodyText(_ message: WebSocketMessage) -> String {
        switch message.message {
        case .string(let text):
            return formattedText(text)
        case .data(let data):
            return binaryBodyText(data)
        @unknown default:
            return "<unknown message type>"
        }
    }

    static func messageMetadata(_ message: WebSocketMessage) -> String {
        "\(formatTime(message.occurredAt)) - \(messageKind(message)) - \(message.byteCount) B"
    }

    static func txtExport(connection: WebSocketModel) -> String {
        var text = ""
        text += "*** Overview *** \n"
        text += "\(overview(connection: connection).1)\n\n"
        text += "*** Request Header *** \n"
        text += "\(header(connection.requestHeaders).1)\n\n"
        text += "*** Response Header *** \n"
        text += "\(header(connection.responseHeaders).1)\n\n"

        text += "*** Messages *** \n"
        if connection.messages.isEmpty {
            text += "No messages captured.\n"
        } else {
            for message in connection.messages {
                text += "[\(formatDate(message.occurredAt))] \(message.direction.title) "
                text += "\(messageKind(message)) \(message.byteCount) B\n"
                text += "\(bodyText(message))\n\n"
            }
        }

        text += "------------------------------------------------------------------------\n"
        text += "------------------------------------------------------------------------\n"
        text += "------------------------------------------------------------------------\n\n\n\n"
        return text
    }

    private static func messageKind(_ message: WebSocketMessage) -> String {
        switch message.message {
        case .string: return "text"
        case .data: return "data"
        @unknown default: return "unknown"
        }
    }

    private static func formattedText(_ text: String, maximumLength: Int? = nil) -> String {
        let formatted = text.prettyPrintedJSON ?? text

        guard let maximumLength, formatted.count > maximumLength else {
            return formatted
        }

        let endIndex = formatted.index(formatted.startIndex, offsetBy: maximumLength)
        return String(formatted[..<endIndex]) + "..."
    }

    private static func binaryBodyText(_ data: Data, maximumByteCount: Int? = nil) -> String {
        let visibleData: Data
        let isTruncated: Bool

        if let maximumByteCount, data.count > maximumByteCount {
            visibleData = Data(data.prefix(maximumByteCount))
            isTruncated = true
        } else {
            visibleData = data
            isTruncated = false
        }

        return "Base64 (\(data.count) bytes): \(visibleData.base64EncodedString())\(isTruncated ? "..." : "")"
    }

    private static func duration(_ connection: WebSocketModel) -> String {
        let endDate = connection.closedAt ?? connection.failedAt ?? Date()
        guard endDate >= connection.startDate else { return "-" }
        return (endDate.timeIntervalSince(connection.startDate) * 1000).formattedMilliseconds()
    }

    private static func formatDate(_ date: Date?) -> String {
        date?.stringWithFormat(dateFormat: "MMM d yyyy - HH:mm:ss.SSS") ?? "-"
    }

    private static func formatTime(_ date: Date) -> String {
        date.stringWithFormat(dateFormat: "HH:mm:ss.SSS") ?? "-"
    }
}
