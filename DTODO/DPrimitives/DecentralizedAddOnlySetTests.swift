//  Created by Denis Malykh on 19.04.2021.

import Foundation
import XCTest

@testable import DTODO

final class DecentralizedAddOnlySetTests: XCTestCase {
    func testInitialCreation() {
        let set = DecentralizedAddOnlySet<Int>()
        XCTAssertTrue(set.values.isEmpty)
    }

    func testAddingValues() {
        var set = DecentralizedAddOnlySet<Int>()

        set.insert(2)
        XCTAssertEqual(set.values.count, 1)
        XCTAssertTrue(set.values.contains(2))

        set.insert(3)
        XCTAssertEqual(set.values.count, 2)
        XCTAssertTrue(set.values.contains(2))
        XCTAssertTrue(set.values.contains(3))
    }

    func testAssociativity() {
        var one = DecentralizedAddOnlySet<Int>()
        var two = DecentralizedAddOnlySet<Int>()
        one.insert(2)
        two.insert(3)
        var three = DecentralizedAddOnlySet<Int>()
        three.insert(4)
        let lhs = one.merged(with: two).merged(with: three)
        let rhs = one.merged(with: two.merged(with: three))
        XCTAssertEqual(lhs.values, rhs.values)
    }

    func testCommutativity() {
        var one = DecentralizedAddOnlySet<Int>()
        var two = DecentralizedAddOnlySet<Int>()
        one.insert(2)
        two.insert(3)
        let lhs = one.merged(with: two)
        let rhs = two.merged(with: one)
        XCTAssertEqual(lhs.values, rhs.values)
    }

    func testIdempotency() {
        var one = DecentralizedAddOnlySet<Int>()
        var two = DecentralizedAddOnlySet<Int>()
        one.insert(2)
        two.insert(3)
        let check1 = one.merged(with: two)
        let check2 = check1.merged(with: two)
        let check3 = check1.merged(with: one)
        XCTAssertEqual(check1.values, check2.values)
        XCTAssertEqual(check1.values, check3.values)
    }

    func testCodable() {
        var set = DecentralizedAddOnlySet<Int>()
        set.insert(2)
        set.insert(3)
        let data = try! JSONEncoder().encode(set)
        let setd = try! JSONDecoder().decode(DecentralizedAddOnlySet<Int>.self, from: data)
        XCTAssertEqual(set, setd)
    }
}
