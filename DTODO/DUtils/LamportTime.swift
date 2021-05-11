//  Created by Denis Malykh on 19.04.2021.

import Foundation

public struct LamportTime: Codable, Identifiable, Comparable, Hashable {
    public private(set) var time: Int64
    public private(set) var id: UUID

    public init(time: Int64 = 0, id: UUID = UUID()) {
        self.time = time
        self.id = id
    }

    @discardableResult
    public mutating func tick() -> LamportTime {
        time += 1
        id = UUID()
        
        return self
    }

    public static func < (lhs: LamportTime, rhs: LamportTime) -> Bool {
        (lhs.time, lhs.id.uuidString) < (rhs.time, rhs.id.uuidString)
    }

    public static func > (lhs: LamportTime, rhs: LamportTime) -> Bool {
        (lhs.time, lhs.id.uuidString) > (rhs.time, rhs.id.uuidString)
    }
}
