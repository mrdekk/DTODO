//  Created by Denis Malykh on 26.04.2021.

import Foundation

public struct DecentralizedArray<T> {
    fileprivate struct Metadata: Identifiable {
        var anchor: ID?
        var value: T
        var time: LamportTime
        var id: UUID = UUID()
        var isDeleted: Bool

        init(anchor: Metadata.ID?, value: T, time: LamportTime, isDeleted: Bool = false) {
            self.anchor = anchor
            self.value = value
            self.time = time
            self.isDeleted = isDeleted
        }

        func isOrdered(before other: Metadata) -> Bool {
            (time, id.uuidString) > (other.time, other.id.uuidString)
        }
    }

    private var _values: Array<Metadata> = []
    private var _tombstones: Array<Metadata> = []

    public var values: Array<T> {
        _values.map { $0.value }
    }
    public var count: UInt64 {
        UInt64(_values.count)
    }

    private var currentTime: LamportTime
    private mutating func tick() {
        currentTime.tick()
    }

    // MARK: Init

    public init(currentTime: LamportTime = LamportTime()) {
        self.currentTime = currentTime
    }
}

public extension DecentralizedArray {
    mutating func insert(_ newValue: T, at index: Int) {
        tick()
        let newMeta = makeMetadata(withValue: newValue, forInsertingAtIndex: index)
        _values.insert(newMeta, at: index)
    }

    mutating func append(_ newValue: T) {
        insert(newValue, at: _values.count)
    }

    private func makeMetadata(withValue value: T, forInsertingAtIndex index: Int) -> Metadata {
        let anchor = index > 0 ? _values[index - 1].id : nil
        return Metadata(anchor: anchor, value: value, time: currentTime)
    }
}

public extension DecentralizedArray {
    @discardableResult
    mutating func remove(at index: Int) -> T {
        var tombstone = _values[index]
        tombstone.isDeleted = true
        _tombstones.append(tombstone)
        _values.remove(at: index)
        return tombstone.value
    }
}

extension DecentralizedArray: Decentralized {
    public func merged(with other: Self) -> Self {
        let resultTombstones = (_tombstones + other._tombstones).filterDuplicates { $0.id }
        let tombstoneIds = resultTombstones.map { $0.id }

        var encounteredIds: Set<Metadata.ID> = []
        let unorderedMetas = (_values + other._values).filter {
            !tombstoneIds.contains($0.id) && encounteredIds.insert($0.id).inserted
        }

        let resultMetasWithTombstones = Self.ordered(fromUnordered: unorderedMetas + resultTombstones)
        let resultMetas = resultMetasWithTombstones.filter { !$0.isDeleted }

        var result = self
        result._values = resultMetas
        result._tombstones = resultTombstones
        result.currentTime = Swift.max(self.currentTime, other.currentTime)
        return result
    }

    /// Not just sorted, but ordered according to a preorder traversal of the tree.
    /// For each element, we insert the element itself first, then the child (anchored) subtrees from left to right.

    private static func ordered(fromUnordered unordered: [Metadata]) -> [Metadata] {
        let sorted = unordered.sorted { $0.isOrdered(before: $1) }
        let anchoredByAnchorId: [Metadata.ID? : [Metadata]] = .init(grouping: sorted) { $0.anchor }
        var result: [Metadata] = []

        func addDecendants(of metas: [Metadata]) {
            for meta in metas {
                result.append(meta)
                guard let anchoredToMeta = anchoredByAnchorId[meta.id] else { continue }
                addDecendants(of: anchoredToMeta)
            }
        }

        let roots = anchoredByAnchorId[nil] ?? []
        addDecendants(of: roots)
        return result
    }
}

extension DecentralizedArray: Codable where T: Codable {}
extension DecentralizedArray.Metadata: Codable where T: Codable {}

extension DecentralizedArray: Equatable where T: Equatable {}
extension DecentralizedArray.Metadata: Equatable where T: Equatable {}

extension DecentralizedArray: Hashable where T: Hashable {}
extension DecentralizedArray.Metadata: Hashable where T: Hashable {}

extension DecentralizedArray: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: T...) {
        self.currentTime = LamportTime()
        elements.forEach { self.append($0) }
    }
}

extension DecentralizedArray: Collection, RandomAccessCollection {
    public var startIndex: Int { return _values.startIndex }
    public var endIndex: Int { return _values.endIndex }
    public func index(after i: Int) -> Int { _values.index(after: i) }

    public subscript(_ i: Int) -> T {
        get {
            _values[i].value
        }
        set {
            remove(at: i)
            tick()
            _values.insert(makeMetadata(withValue: newValue, forInsertingAtIndex: i), at: i)
        }
    }
}

private extension Array {
    func filterDuplicates(identifyingWith block: (Element) -> AnyHashable) -> Self {
        var encountered: Set<AnyHashable> = []
        return filter { encountered.insert(block($0)).inserted }
    }
}
