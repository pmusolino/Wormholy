//
//  SearchBar.swift
//  Wormholy
//
//  Created by Paolo Musolino on 21/11/24.
//
import SwiftUI

internal struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    var onTextChanged: () -> Void

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String
        var onTextChanged: () -> Void

        init(text: Binding<String>, onTextChanged: @escaping () -> Void) {
            _text = text
            self.onTextChanged = onTextChanged
        }

        // Called when the text in the search bar changes
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
            onTextChanged()
        }
        
        // Called when the search button is clicked
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder() // Dismiss the keyboard
        }
        
        // Called when the cancel button is clicked
        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder() // Dismiss the keyboard
            text = "" // Clear the search text
            onTextChanged()
        }
        
        // Called when the user begins editing the search bar
        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            searchBar.setShowsCancelButton(true, animated: true) // Show the cancel button
        }
        
        // Called when the user ends editing the search bar
        func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
            searchBar.setShowsCancelButton(false, animated: true) // Hide the cancel button
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, onTextChanged: onTextChanged)
    }

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.placeholder = "Search" // Placeholder text
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text // Update the text in the search bar
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
