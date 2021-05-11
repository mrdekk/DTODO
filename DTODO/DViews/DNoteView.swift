//  Created by Denis Malykh on 05.05.2021.

import SwiftUI

struct DNoteView: View {

    @Binding var note: DNote

    var body: some View {
        VStack {
            HStack {
                TextField("DNote Title", text: $note.title.value)
                Spacer()
            }
            DTextEdit(characters: $note.text)
        }
        .padding()
        .navigationTitle("D Note")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DNoteView_Previews: PreviewProvider {

    @State private static var note = DNote.makeDummyNote()

    static var previews: some View {
        return DNoteView(
            note: $note
        )
    }
}
