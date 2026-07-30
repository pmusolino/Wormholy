//
//  Colors.swift
//  Wormholy-iOS
//
//  Created by Paolo Musolino on 14/04/18.
//  Copyright © 2018 Wormholy. All rights reserved.
//

import SwiftUI

internal struct Colors {
    
    internal struct HTTPCode {
        static let Success = Color(hex: "#297E4C") //2xx
        static let Redirect = Color(hex: "#3D4140") //3xx
        static let ClientError = Color(hex: "#D97853") //4xx
        static let ServerError = Color(hex: "#D32C58") //5xx
        static let Generic = Color(hex: "#999999") //Others
        
        static func getHTTPCodeColor(code: Int) -> Color {
            switch code {
            case 200..<300:
                return Colors.HTTPCode.Success
            case 300..<400:
                return Colors.HTTPCode.Redirect
            case 400..<500:
                return Colors.HTTPCode.ClientError
            case 500..<600:
                return Colors.HTTPCode.ServerError
            default:
                return Colors.HTTPCode.Generic
            }
        }
    }

    internal struct WebSocket {
        static let Connecting = Color(hex: "#D9A441")
        static let Open = Color(hex: "#2E86AB")
        static let Closed = Color(hex: "#6B6F76")
        static let Failed = Color(hex: "#D32C58")

        static func getStateColor(_ state: WebSocketConnectionState) -> Color {
            switch state {
            case .connecting:
                return Colors.WebSocket.Connecting
            case .open:
                return Colors.WebSocket.Open
            case .closed:
                return Colors.WebSocket.Closed
            case .failed:
                return Colors.WebSocket.Failed
            }
        }

        internal struct Direction {
            static let Sent = Color(hex: "#2E86AB")
            static let Received = Color(hex: "#297E4C")

            static func getDirectionColor(_ direction: WebSocketMessageDirection) -> Color {
                switch direction {
                case .sent:
                    return Colors.WebSocket.Direction.Sent
                case .received:
                    return Colors.WebSocket.Direction.Received
                }
            }
        }
    }
}

private extension Color {
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hex)
        if hex.hasPrefix("#") {
            scanner.scanLocation = 1
        }
        
        var color: UInt64 = 0
        scanner.scanHexInt64(&color)
        
        let mask = 0x000000FF
        let r = Double(Int(color >> 16) & mask) / 255.0
        let g = Double(Int(color >> 8) & mask) / 255.0
        let b = Double(Int(color) & mask) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}
