//  Created by Denis Malykh on 07.05.2021.

import Foundation
import SwiftUI

struct Peer: Codable, Identifiable {
    var id = UUID()
    var ip: String

    func makeSnapshotRequest() -> URLRequest? {
        var components = URLComponents()
        components.scheme = "http"
        components.host = ip
        components.port = Constants.port
        components.path = "/snapshot"

        guard let url = components.url else {
            return nil
        }

        var request = URLRequest(url: url)
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        return request
    }
}
