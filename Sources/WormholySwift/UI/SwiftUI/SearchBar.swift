//
//  SearchBar.swift
//  Wormholy
//
//  Created by Paolo Musolino on 21/11/24.
//
import SwiftUI

struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    var onTextChanged: () -> Void

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String
        var onTextChanged: () -> Void

        init(text: Binding<String>, onTextChanged: @escaping () -> Void) {
            _text = text
            self.onTextChanged = onTextChanged
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
            onTextChanged()
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, onTextChanged: onTextChanged)
    }

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.placeholder = "Search URL"
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
}

struct SearchBar_Previews: PreviewProvider {
    @State static var searchText = ""

    static var previews: some View {
        SearchBar(text: $searchText, onTextChanged: {
            print("Text changed to: \(searchText)")
        })
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
