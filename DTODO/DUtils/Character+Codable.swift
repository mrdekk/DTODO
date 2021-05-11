//  Created by Denis Malykh on 26.04.2021.

import Foundation

extension Character: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let string = try container.decode(String.self)
        self = string.first!
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(String(self))
    }
}
