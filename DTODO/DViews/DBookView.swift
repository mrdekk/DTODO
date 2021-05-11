//  Created by Denis Malykh on 05.05.2021.

import SwiftUI

struct DBookView: View {

    @EnvironmentObject var repository: Repository

    var body: some View {
        List {
            ForEach(repository.book.notes) { note in
                NavigationLink(
                    destination: DNoteView(note: self.repository.note(for: note.id))
                ) {
                    Text(note.title.value)
                        .padding(10)
                }
            }
        }
    }
}

struct DBookView_Previews: PreviewProvider {
    static var repository = Repository(overridingBook: DBook.makeDummyBook(count: 10))

    static var previews: some View {
        DBookView()
            .environmentObject(repository)
    }
}
