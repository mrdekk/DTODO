//  Created by Denis Malykh on 19.04.2021.

import Foundation
import XCTest

@testable import DTODO

final class DecentralizedVariableTests: XCTestCase {
    func testInitialCreation() {
        let one = DecentralizedVariable(1)
        XCTAssertEqual(one.value, 1)

        let two = DecentralizedVariable(2)
        XCTAssertEqual(two.value, 2)
    }

    func testSettingValue() {
        var vr = DecentralizedVariable(1)
        vr.value = 2
        XCTAssertEqual(vr.value, 2)
        vr.value = 3
        XCTAssertEqual(vr.value, 3)
    }

    func testMergeInitiallyUnrelated() {
        var time = LamportTime()
        let one = DecentralizedVariable(1, time: time)
        let two = DecentralizedVariable(2, time: time.tick())
        let three = one.merged(with: two)
        XCTAssertEqual(three.value, two.value) // last write wins
    }

    func testLastChangeWins() {
        var one = DecentralizedVariable(1)
        one.value = 3
        let two = DecentralizedVariable(2)
        let three = one.merged(with: two)
        XCTAssertEqual(three.value, one.value)
    }

    func testAssociativity() {
        var time = LamportTime()
        let one = DecentralizedVariable(1, time: time)
        let two = DecentralizedVariable(2, time: time.tick())
        let three = DecentralizedVariable(3, time: time.tick())
        let lhs = one.merged(with: two).merged(with: three)
        let rhs = one.merged(with: two.merged(with: three))
        XCTAssertEqual(lhs.value, rhs.value)
    }

    func testCommutativity() {
        var time = LamportTime()
        let one = DecentralizedVariable(1, time: time)
        let two = DecentralizedVariable(2, time: time.tick())
        let lhs = one.merged(with: two)
        let rhs = two.merged(with: one)
        XCTAssertEqual(lhs.value, rhs.value)
    }

    func testIdempotency() {
        var time = LamportTime()
        let one = DecentralizedVariable(1, time: time)
        let two = DecentralizedVariable(2, time: time.tick())
        let check1 = one.merged(with: two)
        let check2 = check1.merged(with: two)
        let check3 = check1.merged(with: one)
        XCTAssertEqual(check1.value, check2.value)
        XCTAssertEqual(check1.value, check3.value)
    }

    func testCodable() {
        let vr = DecentralizedVariable(1)
        let data = try! JSONEncoder().encode(vr)
        let vrd = try! JSONDecoder().decode(DecentralizedVariable<Int>.self, from: data)
        XCTAssertEqual(vr, vrd)
    }
}

