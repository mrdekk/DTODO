//  Created by Denis Malykh on 19.04.2021.

import Foundation

public protocol Decentralized {
    func merged(with other: Self) -> Self
}
