//  Created by Denis Malykh on 19.04.2021.

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var repository: Repository
    @EnvironmentObject var configStore: ConfigurationStore

    var body: some View {
        NavigationView {
            DBookView()
                .navigationBarTitle(Text("Decentralized Notes"))
                .navigationBarItems(
                    trailing: HStack {
                        Button(
                            action: {
                                withAnimation { self.repository.addEmptyNote() }
                            }
                        ) {
                            Image(systemName: "plus")
                        }
                            .padding(.trailing, 8)
                        Button(
                            action: {
                                self.repository.communicateToPeers(self.configStore.configuration.peers)
                            }
                        ) {
                            Image(systemName: "arrow.3.trianglepath")
                        }
                            .padding(.trailing, 8)
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape")
                        }
                    }
                )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var repository = Repository(overridingBook: DBook.makeDummyBook(count: 10))
    static var previews: some View {
        ContentView()
            .environmentObject(repository)
    }
}
