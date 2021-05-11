//  Created by Denis Malykh on 19.04.2021.

import Foundation

public struct DecentralizedVariable<T> {
    fileprivate struct Metadata: Identifiable {
        var value: T
        var time: LamportTime
        var id: UUID

        init(value: T, time: LamportTime = LamportTime(), id: UUID = UUID()) {
            self.value = value
            self.time = time
            self.id = id
        }

        func isHappens(after other: Metadata) -> Bool {
            (time, id.uuidString) > (other.time, other.id.uuidString)
        }
    }

    private var meta: Metadata

    public var value: T {
        get {
            meta.value
        }
        set {
            var time = meta.time
            time.tick()
            meta = Metadata(value: newValue, time: time)
        }
    }

    public init(_ value: T, time: LamportTime = LamportTime()) {
        self.meta = Metadata(value: value, time: time)
    }
}

extension DecentralizedVariable: Decentralized {
    public func merged(with other: DecentralizedVariable<T>) -> DecentralizedVariable<T> {
        meta.isHappens(after: other.meta) ? self : other
    }
}

extension DecentralizedVariable: Equatable where T: Equatable {}
extension DecentralizedVariable.Metadata: Equatable where T: Equatable {}

extension DecentralizedVariable: Hashable where T: Hashable {}
extension DecentralizedVariable.Metadata: Hashable where T: Hashable {}

extension DecentralizedVariable: Codable where T: Codable {}
extension DecentralizedVariable.Metadata: Codable where T: Codable {}
