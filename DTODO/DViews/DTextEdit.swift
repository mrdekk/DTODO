//  Created by Denis Malykh on 05.05.2021.

import SwiftUI

struct DTextEdit: View {
    @Binding var characters: DecentralizedArray<Character>
    private var text: String { String(characters.values) }

    @State private var editingText: String = ""

    var body: some View {
        TextEditor(text: $editingText)
            .border(Color(white: 0))
            .onAppear { textToEditing() }
            .onChange(of: characters) { _ in
                textToEditing()
            }
            .onChange(of: editingText) { _ in
                editingToText()
            }
    }

    private func textToEditing() {
        let logicText = text
        if logicText != editingText {
            editingText = logicText
        }
    }

    private func editingToText() {
        guard editingText != text else { return }

        let delta = editingText.difference(from: text)
        var newCharacters = characters
        for item in delta {
            switch item {
            case let .insert(offset, element, _): newCharacters.insert(element, at: offset)
            case let .remove(offset, _, _): newCharacters.remove(at: offset)
            }
        }
        characters = newCharacters
    }
}
