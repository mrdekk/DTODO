//  Created by Denis Malykh on 07.05.2021.

import SwiftUI

struct PeerView: View {

    @Binding var peer: Peer
    @State private var peerIp: String

    init(peer: Binding<Peer>) {
        self._peer = peer
        self._peerIp = State(initialValue: peer.wrappedValue.ip)
    }
    
    var body: some View {
        TextField("IP", text: $peerIp)
            .onChange(of: peerIp) { newPeerIp in
                peer.ip = newPeerIp
            }
    }
}
