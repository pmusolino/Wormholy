//
//  RequestCellView.swift
//  Wormholy
//
//  Created by Paolo Musolino on 21/11/24.
//
import SwiftUI

struct RequestCellView: View {
    var request: RequestModel

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
                        .padding(3)
                        .background(RoundedRectangle(cornerRadius: 6)
                                        .stroke(getCodeColor(code: request.code), lineWidth: 0.5))
                        .foregroundColor(getCodeColor(code: request.code))
                }
                
                if let duration = request.duration {
                    Text(duration.formattedMilliseconds())
                        .font(.footnote)
                }
            }
            .frame(width: 50, alignment: .leading)
            .padding(.leading, 8)
            
            Text(request.url)
                .font(.footnote)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .padding([.leading, .trailing], 8)
            
            Spacer()
        }
    }
    
    private func getCodeColor(code: Int) -> Color {
        switch code {
        case 200..<300:
            return Color(Colors.HTTPCode.Success)
        case 300..<400:
            return Color(Colors.HTTPCode.Redirect)
        case 400..<500:
            return Color(Colors.HTTPCode.ClientError)
        case 500..<600:
            return Color(Colors.HTTPCode.ServerError)
        default:
            return Color(Colors.HTTPCode.Generic)
        }
    }
}
