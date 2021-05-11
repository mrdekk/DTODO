//  Created by Denis Malykh on 07.05.2021.

import Foundation
import SwiftUI

class ConfigurationStore: ObservableObject {
    @Published var configuration: Configuration

    init() {
        self.configuration = Configuration.load()
    }

    func peer(for id: UUID) -> Binding<Peer> {
        .init(
            get: { () -> Peer in
                self.configuration.peers.first(where: { $0.id == id })!
            },
            set: { newPeer in
                let idx = self.configuration.peers.firstIndex(where: { $0.id == id })!
                self.configuration.peers[idx] = newPeer
            }
        )
    }

    func addNewPeer() {
        configuration.peers.append(Peer(ip: "..."))
    }
}
