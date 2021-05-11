//  Created by Denis Malykh on 26.04.2021.

import Foundation
import XCTest

@testable import DTODO

final class DecentralizedArrayTests: XCTestCase {

    func testInitialCreation() {
        let arr = DecentralizedArray<Int>()
        XCTAssertEqual(arr.count, 0)
    }

    func testAppending() {
        var arr = DecentralizedArray<Int>()
        arr.append(1)
        arr.append(2)
        arr.append(3)
        XCTAssertEqual(arr.values, [1,2,3])
    }

    func testInserting() {
        var arr = DecentralizedArray<Int>()
        arr.insert(1, at: 0)
        arr.insert(2, at: 0)
        arr.insert(3, at: 0)
        XCTAssertEqual(arr.values, [3,2,1])
    }

    func testRemoving() {
        var arr = DecentralizedArray<Int>()
        arr.append(1)
        arr.append(2)
        arr.append(3)
        arr.remove(at: 1)
        XCTAssertEqual(arr.values, [1,3])
        XCTAssertEqual(arr.count, 2)
    }

    func testInterleavedInsertAndRemove() {
        var arr = DecentralizedArray<Int>()
        arr.append(1)
        arr.append(2)
        arr.remove(at: 1) // [1]
        arr.append(3)
        arr.remove(at: 0) // [3]
        arr.append(1)
        arr.append(2)
        arr.remove(at: 1) // [3,2]
        arr.append(3)
        XCTAssertEqual(arr.values, [3,2,3])
    }

    func testMergeOfInitiallyUnrelated() {
        var time = LamportTime()
        var one = DecentralizedArray<Int>(currentTime: time)
        one.append(1); time.tick()
        one.append(2); time.tick()
        one.append(3); time.tick()

        // Force the lamport of b higher, so it comes first
        var two = DecentralizedArray<Int>(currentTime: time)
        two.append(1)
        two.remove(at: 0)
        two.append(7)
        two.append(8)
        two.append(9)

        let three = one.merged(with: two)
        XCTAssertEqual(three.values, [7,8,9,1,2,3])
    }

    func testMergeWithRemoves() {
        var one = DecentralizedArray<Int>()
        one.append(1)
        one.append(2)
        one.append(3)
        one.remove(at: 1)

        var two = DecentralizedArray<Int>()
        two.append(1)
        two.remove(at: 0)
        two.append(7)
        two.append(8)
        two.append(9)
        two.remove(at: 1)

        let three = two.merged(with: one)
        XCTAssertEqual(three.values, [7,9,1,3])
    }

    func testMultipleMerges() {
        var one = DecentralizedArray<Int>()
        one.append(1)
        one.append(2)
        one.append(3)

        var two = DecentralizedArray<Int>()
        two = two.merged(with: one)

        // Force b lamport higher
        two.insert(1, at: 0)
        two.remove(at: 0)

        two.insert(1, at: 0)
        two.append(5) // [1,1,2,3,5]

        one.append(6) // [1,2,3,6]

        XCTAssertEqual(one.merged(with: two).values, [1,1,2,3,5,6])
    }

    func testIdempotency() {
        var one = DecentralizedArray<Int>()
        one.append(1)
        one.append(2)
        one.append(3)
        one.remove(at: 1)

        var two = DecentralizedArray<Int>()
        two.append(1)
        two.remove(at: 0)
        two.append(7)
        two.append(8)
        two.append(9)
        two.remove(at: 1)

        let three = one.merged(with: two)
        let lhs = three.merged(with: two)
        let rhs = three.merged(with: one)
        XCTAssertEqual(three.values, lhs.values)
        XCTAssertEqual(three.values, rhs.values)
    }

    func testCommutivity() {
        var one = DecentralizedArray<Int>()
        one.append(1)
        one.append(2)
        one.append(3)
        one.remove(at: 1)

        var two = DecentralizedArray<Int>()
        two.append(1)
        two.remove(at: 0)
        two.append(7)
        two.append(8)
        two.append(9)
        two.remove(at: 1)

        let lhs = one.merged(with: two)
        let rhs = two.merged(with: one)
        XCTAssertEqual(rhs.values, [7,9,1,3])
        XCTAssertEqual(rhs.values, lhs.values)
    }

    func testAssociativity() {
        var one = DecentralizedArray<Int>()
        one.append(1)
        one.append(2)
        one.remove(at: 1)
        one.append(3)

        var two = DecentralizedArray<Int>()
        two.append(5)
        two.append(6)
        two.append(7)

        var three: DecentralizedArray<Int> = [10,11,12]
        three.remove(at: 0)

        let lhs = one.merged(with: two).merged(with: three)
        let rhs = one.merged(with: two.merged(with: three))
        XCTAssertEqual(lhs.values, rhs.values)
    }

    func testCodable() {
        var arr = DecentralizedArray<Int>()
        arr.append(1)
        arr.append(2)
        arr.remove(at: 1)
        arr.append(3)

        let data = try! JSONEncoder().encode(arr)
        let arrd = try! JSONDecoder().decode(DecentralizedArray<Int>.self, from: data)
        XCTAssertEqual(arrd.values, arr.values)
    }

}
