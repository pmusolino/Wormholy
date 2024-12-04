//
//  RequestCellView.swift
//  Wormholy
//
//  Created by Paolo Musolino on 21/11/24.
//

import SwiftUI

internal struct RequestCellView: View {
    @ObservedObject var request: RequestModel

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(request.method.uppercased())
                    .font(.subheadline)
                    .bold()
                
                if request.code != 0 {
                    Text("\(request.code)")
                        .font(.caption)
                        .bold()
                        .padding(4)
                        .background(RoundedRectangle(cornerRadius: 6)
                                        .stroke(Colors.HTTPCode.getHTTPCodeColor(code: request.code), lineWidth: 0.5))
                        .foregroundColor(Colors.HTTPCode.getHTTPCodeColor(code: request.code))
                }
                
                if let duration = request.duration {
                    Text(duration.formattedMilliseconds())
                        .font(.footnote)
                }
            }
            .frame(width: 50, alignment: .leading)
            
            Text(request.url)
                .font(.subheadline)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .padding([.leading, .trailing], 8)
            
            Spacer()
        }
    }
}

struct RequestCellView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a fake request for preview
        let fakeRequest = RequestModel(
            id: UUID().uuidString,
            url: "https://example.com/api/v1/resources/items/12345/details?include=all&expand=full",
            host: "example.com",
            port: 443,
            scheme: "https",
            startDate: Date(),
            method: "GET",
            headers: [
                "Content-Type": "application/json",
                "Authorization": "Bearer token",
                "Accept": "application/json",
                "User-Agent": "Wormholy/1.0"
            ],
            credentials: ["user": "password"],
            cookies: "sessionid=abc123;",
            httpBody: nil,
            code: 200,
            responseHeaders: [
                "Content-Type": "application/json",
                "Cache-Control": "no-cache",
                "Server": "Apache/2.4.41 (Ubuntu)"
            ],
            dataResponse: nil,
            errorClientDescription: nil,
            duration: 1.23
        )
        
        RequestCellView(request: fakeRequest)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
