//  Created by Denis Malykh on 07.05.2021.

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var configurationStore: ConfigurationStore

    var body: some View {
        VStack {
            HStack {
                Text("Peers")
                Spacer()
                Button(
                    action: {
                        withAnimation { self.configurationStore.addNewPeer() }
                    }
                ) {
                    Image(systemName: "plus")
                }
            }
                .padding()
            List {
                ForEach(configurationStore.configuration.peers) { peer in
                    PeerView(peer: configurationStore.peer(for: peer.id))
                }
            }
        }
        .navigationTitle("Settings")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var store = ConfigurationStore()
    static var previews: some View {
        SettingsView()
            .environmentObject(store)
    }
}
