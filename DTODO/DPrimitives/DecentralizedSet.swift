//  Created by Denis Malykh on 19.04.2021.

import Foundation

public struct DecentralizedSet<T: Hashable> {
  fileprivate struct Metadata {
    var isDeleted: Bool
    var time: LamportTime

    init(isDeleted: Bool = false, time: LamportTime) {
      self.isDeleted = isDeleted
      self.time = time
    }
  }

  private var metadata: Dictionary<T, Metadata>
  private var currentTime: LamportTime

  public var count: Int {
    metadata.reduce(0) { result, meta in
      result + (meta.value.isDeleted ? 0 : 1)
    }
  }

    public init(time: LamportTime = LamportTime()) {
    self.metadata = [T: Metadata]()
    self.currentTime = time
  }

  public init(array elements: [T]) {
    self = .init()
    elements.forEach { self.insert($0) }
  }

  @discardableResult
  public mutating func insert(_ value: T) -> Bool {
    currentTime.tick()

    let meta = Metadata(time: currentTime)
    let isNewInsert = metadata[value]?.isDeleted ?? true
    metadata[value] = meta

    return isNewInsert
  }

  @discardableResult
  public mutating func remove(_ value: T) -> T? {
    guard let oldMeta = metadata[value], !oldMeta.isDeleted else {
      return nil
    }

    currentTime.tick()
    metadata[value] = Metadata(isDeleted: true, time: currentTime)

    return value
  }

  public var values: Set<T> {
    let values = metadata
      .filter { !$1.isDeleted }
      .map { $0.key }
    return Set(values)
  }

  public func contains(_ value: T) -> Bool {
    !(metadata[value]?.isDeleted ?? true)
  }
}

extension DecentralizedSet: Decentralized {
  public func merged(with other: DecentralizedSet<T>) -> DecentralizedSet<T> {
    var result = self
    result.metadata = other.metadata.reduce(into: metadata) { result, meta in
      let lhs = result[meta.key]
      let rhs = meta.value
      if let lhs = lhs {
        result[meta.key] = lhs.time > rhs.time ? lhs : rhs
      } else {
        result[meta.key] = rhs
      }
    }
    result.currentTime = Swift.max(self.currentTime, other.currentTime)
    return result
  }
}

extension DecentralizedSet: Codable where T: Codable {}
extension DecentralizedSet.Metadata: Codable where T: Codable {}

extension DecentralizedSet: Equatable where T: Equatable {}
extension DecentralizedSet.Metadata: Equatable where T: Equatable {}

extension DecentralizedSet: Hashable where T: Hashable {}
extension DecentralizedSet.Metadata: Hashable where T: Hashable {}

extension DecentralizedSet: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: T...) {
    self = .init(array: elements)
  }
}
