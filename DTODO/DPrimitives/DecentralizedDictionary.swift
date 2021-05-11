//  Created by Denis Malykh on 19.04.2021.

import Foundation

public struct DecentralizedDictionary<Key, Value> where Key: Hashable {
    fileprivate struct Metadata {
        var isDeleted: Bool
        var time: LamportTime
        var value: Value

        init(isDeleted: Bool = false, value: Value, time: LamportTime) {
            self.isDeleted = isDeleted
            self.time = time
            self.value = value
        }
    }

    private var metadata: Dictionary<Key, Metadata>
    private var currentTime: LamportTime

    private var existingKeyValuePairs: [(key: Key, value: Metadata)] {
        metadata.filter { meta in !meta.value.isDeleted }
    }

    public var values: [Value] {
        existingKeyValuePairs.map { meta in meta.value.value }
    }

    public var keys: [Key] {
        existingKeyValuePairs.map { meta in meta.key }
    }

    public var dictionary: [Key: Value] {
        existingKeyValuePairs.reduce(into: [:]) { res, meta in
            res[meta.key] = meta.value.value
        }
    }

    public var count: Int {
        metadata.reduce(into: 0) { res, meta in
            res += (meta.value.isDeleted ? 0 : 1)
        }
    }

    public init(time: LamportTime = LamportTime()) {
        self.metadata = [Key: Metadata]()
        self.currentTime = time
    }

    public subscript(key: Key) -> Value? {
        get {
            guard let meta = metadata[key], !meta.isDeleted else {
                return nil
            }

            return meta.value
        }
        set(newValue) {
            currentTime.tick()
            if let newValue = newValue {
                metadata[key] = Metadata(value: newValue, time: currentTime)
            } else if let oldMeta = metadata[key] {
                metadata[key] = Metadata(isDeleted: true, value: oldMeta.value, time: currentTime)
            }
        }
    }

}

extension DecentralizedDictionary: Decentralized {
    public func merged(with other: DecentralizedDictionary<Key, Value>) -> DecentralizedDictionary<Key, Value> {
        var result = self
        result.metadata = other.metadata.reduce(into: metadata) { res, meta in
            let firstMeta = res[meta.key]
            let secondMeta = meta.value
            if let firstMeta = firstMeta {
                res[meta.key] = firstMeta.time > secondMeta.time ? firstMeta : secondMeta
            } else {
                res[meta.key] = secondMeta
            }
        }
        result.currentTime = max(currentTime, other.currentTime)
        return result
    }
}

extension DecentralizedDictionary where Value: Decentralized {
    public func merged(with other: DecentralizedDictionary) -> DecentralizedDictionary {
        var haveTicked = false
        var resultDictionary = self
        resultDictionary.currentTime = max(self.currentTime, other.currentTime)
        resultDictionary.metadata = other.metadata.reduce(into: metadata) { result, meta in
            let first = result[meta.key]
            let second = meta.value
            if let first = first {
                if !first.isDeleted, !second.isDeleted {
                    // Merge the values
                    if !haveTicked {
                        resultDictionary.currentTime.tick()
                        haveTicked = true
                    }
                    let newValue = first.value.merged(with: second.value)
                    let newMeta = Metadata(value: newValue, time: resultDictionary.currentTime)
                    result[meta.key] = newMeta
                } else {
                    // At least one deletion, so just revert to atomic merge
                    result[meta.key] = first.time > second.time ? first : second
                }
            } else {
                result[meta.key] = second
            }
        }
        return resultDictionary
    }

}

extension DecentralizedDictionary: Codable where Value: Codable, Key: Codable {}
extension DecentralizedDictionary.Metadata: Codable where Value: Codable, Key: Codable {}

extension DecentralizedDictionary: Equatable where Value: Equatable {}
extension DecentralizedDictionary.Metadata: Equatable where Value: Equatable {}

extension DecentralizedDictionary: Hashable where Value: Hashable {}
extension DecentralizedDictionary.Metadata: Hashable where Value: Hashable {}

