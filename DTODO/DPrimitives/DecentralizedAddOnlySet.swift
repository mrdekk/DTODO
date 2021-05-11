//  Created by Denis Malykh on 19.04.2021.

import Foundation

public struct DecentralizedAddOnlySet<T: Hashable> {
    private var storage: Set<T>

    public mutating func insert(_ entry: T) {
        storage.insert(entry)
    }

    public var values: Set<T> {
        storage
    }

    public init() {
        storage = .init()
    }

    public init(_ values: Set<T>) {
        storage = values
    }
}

extension DecentralizedAddOnlySet: Decentralized {
    public func merged(with other: DecentralizedAddOnlySet<T>) -> DecentralizedAddOnlySet<T> {
        DecentralizedAddOnlySet(storage.union(other.storage))
    }
}

extension DecentralizedAddOnlySet: Equatable where T: Equatable {}
extension DecentralizedAddOnlySet: Hashable where T: Hashable {}
extension DecentralizedAddOnlySet: Codable where T: Codable {}

