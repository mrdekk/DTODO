//  Created by Denis Malykh on 07.05.2021.

import Foundation
import SwiftUI

struct Configuration: Codable {
    var peers: [Peer]

    mutating func addPeer(_ peer: Peer) {
        peers.append(peer)
    }

    static func empty() -> Configuration {
        Configuration(
            peers: []
        )
    }

    static func load() -> Configuration {
        let ud = UserDefaults.standard
        if let serialized = ud.data(forKey: confKey) {
            return (try? JSONDecoder().decode(Configuration.self, from: serialized)) ?? .empty()
        }

        return empty()
    }

    func save() {
        let ud = UserDefaults.standard
        do {
            let data = try JSONEncoder().encode(self)
            ud.set(data, forKey: confKey)
        } catch {
            // do nothing yet
        }
    }
}

private let confKey = "__configuration"
