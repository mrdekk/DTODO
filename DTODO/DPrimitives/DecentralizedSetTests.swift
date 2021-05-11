//  Created by Denis Malykh on 19.04.2021.

import Foundation
import XCTest

@testable import DTODO

final class DecentralizedSetTests: XCTestCase {

//    var a: ReplicatingSet<Int>!
//    var b: ReplicatingSet<Int>!
//
//    override func setUp() {
//        super.setUp()
//        a = []
//        b = []
//    }

    func testInitialCreation() {
        let one = DecentralizedSet<Int>()
        XCTAssertEqual(one.count, 0)
    }

    func testAppending() {
        var set = DecentralizedSet<Int>()
        set.insert(1)
        set.insert(2)
        set.insert(3)
        XCTAssertEqual(set.values, [1,2,3])
    }

    func testInserting() {
        var set = DecentralizedSet<Int>()
        set.insert(1)
        set.insert(2)
        set.insert(3)
        XCTAssertEqual(set.values, Set([3,2,1]))
    }

    func testRemoving() {
        var set = DecentralizedSet<Int>()
        set.insert(1)
        set.insert(2)
        set.insert(3)
        set.remove(2)
        XCTAssertEqual(set.values, Set([1,3]))
        XCTAssertEqual(set.count, 2)
    }

    func testInterleavedInsertAndRemove() {
        var set = DecentralizedSet<Int>()
        set.insert(1)
        set.insert(2)
        set.remove(1) // 2
        set.insert(3)
        set.remove(2) // 3
        set.insert(1)
        set.insert(2) // 1,2,3
        set.remove(1) // 2,3
        set.insert(3) // 2,3
        XCTAssertEqual(set.values, Set([2,3]))
    }

    func testMergeOfInitiallyUnrelated() {
        var time = LamportTime()
        var one = DecentralizedSet<Int>(time: time)
        one.insert(1); time.tick()
        one.insert(2); time.tick()
        one.insert(3); time.tick()

        // Force the lamport of b higher, so it comes first
        var two = DecentralizedSet<Int>(time: time.tick())
        two.insert(10)
        two.remove(10)
        two.insert(7)
        two.insert(8)
        two.insert(9)

        let three = one.merged(with: two)
        XCTAssertEqual(three.values, Set([7,8,9,1,2,3]))
    }

    func testMergeWithRemoves() {
        var one = DecentralizedSet<Int>()
        one.insert(1)
        one.insert(2)
        one.insert(3)
        one.remove(1) // 2,3

        var two = DecentralizedSet<Int>()
        two.insert(1)
        two.remove(0)
        two.insert(7)
        two.insert(8)
        two.insert(9)
        two.remove(1) // 7,8,9

        let three = two.merged(with: one)
        XCTAssertEqual(three.values, Set([2,3,7,8,9]))
    }

    func testMultipleMerges() {
        var one = DecentralizedSet<Int>()
        one.insert(1)
        one.insert(2)
        one.insert(3)

        var two = DecentralizedSet<Int>()
        two = two.merged(with: one)

        // Force b lamport higher
        two.insert(10)
        two.remove(10)

        two.insert(1)
        two.insert(5) // [1,2,3,5]

        one.insert(6) // [1,2,3,6]

        XCTAssertEqual(one.merged(with: two).values, Set([1,2,3,5,6]))
    }

    func testIdempotency() {
        var one = DecentralizedSet<Int>()
        one.insert(1)
        one.insert(2)
        one.insert(3)
        one.remove(1)

        var two = DecentralizedSet<Int>()
        two.insert(1)
        two.remove(1)
        two.insert(7)
        two.insert(8)
        two.insert(9)
        two.remove(8)

        let check1 = one.merged(with: two)
        let check2 = check1.merged(with: two)
        let check3 = check1.merged(with: one)
        XCTAssertEqual(check1.values, check2.values)
        XCTAssertEqual(check1.values, check3.values)
    }

    func testCommutivity() {
        var one = DecentralizedSet<Int>()
        one.insert(1)
        one.insert(2)
        one.insert(3)
        one.remove(2)

        var two = DecentralizedSet<Int>()
        two.insert(10)
        two.remove(10)
        two.insert(7)
        two.insert(8)
        two.insert(9)
        two.remove(8)

        let lhs = one.merged(with: two)
        let rhs = two.merged(with: one)
        XCTAssertEqual(rhs.values, Set([7,9,1,3]))
        XCTAssertEqual(rhs.values, lhs.values)
    }

    func testAssociativity() {
        var one = DecentralizedSet<Int>()
        one.insert(1)
        one.insert(2)
        one.remove(2)
        one.insert(3)

        var two = DecentralizedSet<Int>()
        two.insert(5)
        two.insert(6)
        two.insert(7)

        var three: DecentralizedSet<Int> = [10,11,12]
        three.remove(10)

        let lhs = one.merged(with: two).merged(with: three)
        let rhs = one.merged(with: two.merged(with: three))
        XCTAssertEqual(lhs.values, rhs.values)
    }

    func testCodable() {
        var set = DecentralizedSet<Int>()
        set.insert(1)
        set.insert(2)
        set.remove(2)
        set.insert(3)

        let data = try! JSONEncoder().encode(set)
        let setd = try! JSONDecoder().decode(DecentralizedSet<Int>.self, from: data)
        XCTAssertEqual(setd.values, set.values)
    }
}
