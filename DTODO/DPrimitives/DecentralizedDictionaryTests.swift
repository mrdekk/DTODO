//  Created by Denis Malykh on 19.04.2021.

import Foundation
import XCTest

@testable import DTODO

final class DecentralizedDictionaryTests: XCTestCase {
    func testInitialCreation() {
        let dict = DecentralizedDictionary<String, Int>()
        XCTAssertEqual(dict.count, 0)

        let dset = DecentralizedDictionary<String, DecentralizedSet<Int>>()
        XCTAssertEqual(dset.count, 0)
    }

    func testInserting() {
        var dict = DecentralizedDictionary<String, Int>()
        dict["1"] = 1
        dict["2"] = 2
        dict["3"] = 3
        XCTAssertEqual(dict.values.sorted(), [1,2,3])
        XCTAssertEqual(dict.keys.sorted(), ["1","2","3"])
    }

    func testReplacing() {
        var dict = DecentralizedDictionary<String, Int>()
        dict["1"] = 1
        dict["2"] = 2
        dict["3"] = 3
        XCTAssertEqual(dict["2"], 2)

        dict["2"] = 4
        XCTAssertEqual(dict["2"], 4)
    }

    func testRemoving() {
        var dict = DecentralizedDictionary<String, Int>()
        dict["1"] = 1
        dict["2"] = 2
        dict["3"] = 3
        dict["1"] = nil
        XCTAssertEqual(dict.values.sorted(), [2,3])
        XCTAssertEqual(dict.keys.sorted(), ["2","3"])
    }

    func testInterleavedInsertAndRemove() {
        var dict = DecentralizedDictionary<String, Int>()
        dict["1"] = 1
        dict["2"] = 2
        dict["3"] = 3

        dict["2"] = nil
        XCTAssertNil(dict["2"])

        dict["2"] = 4
        dict["3"] = 5
        XCTAssertEqual(dict["2"], 4)
        XCTAssertEqual(dict["3"], 5)

        dict["2"] = nil
        dict["2"] = nil
        dict["3"] = 6
        XCTAssertNil(dict["2"])
        XCTAssertEqual(dict["3"], 6)
    }

    func testMergeOfInitiallyUnrelated() {
        var time = LamportTime()
        var one = DecentralizedDictionary<String, Int>(time: time)
        one["1"] = 1; time.tick()
        one["2"] = 2; time.tick()
        one["3"] = 3; time.tick()
        one["6"] = 8; time.tick()

        // Force the lamport of b higher, so it comes first
        var two = DecentralizedDictionary<String, Int>(time: time.tick())
        two["1"] = 4
        two["1"] = nil
        two["1"] = 4
        two["2"] = 5
        two["3"] = 6
        two["4"] = 7

        let three = one.merged(with: two)
        XCTAssertEqual(three.values.sorted(), [4,5,6,7,8])
    }

    func testMultipleMerges() {
        var one = DecentralizedDictionary<String, Int>()
        one["1"] = 1
        one["2"] = 2
        one["3"] = 3

        var two = DecentralizedDictionary<String, Int>()
        two = two.merged(with: one)

        // Force the lamport of b higher, so it comes first
        two["4"] = 4
        two["4"] = nil

        two["1"] = 10
        two["5"] = 11

        two["4"] = 12
        one["6"] = 12

        let three = one.merged(with: two)
        XCTAssertEqual(three.values.sorted(), [2,3,10,11,12,12])
        XCTAssertEqual(three.keys.sorted(), ["1","2","3","4","5","6"])
        XCTAssertEqual(three["1"], 10)
        XCTAssertEqual(three["4"], 12)
        XCTAssertEqual(three["6"], 12)
    }

    func testIdempotency() {
        var one = DecentralizedDictionary<String, Int>()
        one["1"] = 1
        one["2"] = 2
        one["3"] = 3
        one["2"] = nil

        var two = DecentralizedDictionary<String, Int>()
        two["1"] = 4
        two["1"] = nil
        two["1"] = 4
        two["3"] = 6
        two["2"] = nil

        let check1 = one.merged(with: two)
        let check2 = check1.merged(with: two)
        let check3 = check1.merged(with: one)
        XCTAssertEqual(check1.dictionary, check2.dictionary)
        XCTAssertEqual(check1.dictionary, check3.dictionary)
    }

    func testCommutivity() {
        var one = DecentralizedDictionary<String, Int>()
        one["1"] = 1
        one["2"] = 2
        one["3"] = 3
        one["2"] = nil

        var two = DecentralizedDictionary<String, Int>()
        two["1"] = 4
        two["1"] = nil
        two["1"] = 4
        two["3"] = 6
        two["2"] = nil

        let lhs = one.merged(with: two)
        let rhs = two.merged(with: one)
        XCTAssertEqual(lhs.dictionary, rhs.dictionary)
    }

    func testAssociativity() {
        var one = DecentralizedDictionary<String, Int>()
        one["1"] = 1
        one["2"] = 2
        one["3"] = 3
        one["2"] = nil

        var two = DecentralizedDictionary<String, Int>()
        two["1"] = 4
        two["1"] = nil
        two["1"] = 4
        two["3"] = 6
        two["2"] = nil

        var three = one
        three["1"] = nil

        let lhs = one.merged(with: two).merged(with: three)
        let rhs = one.merged(with: two.merged(with: three))
        XCTAssertEqual(lhs.values, rhs.values)
    }

    func testNonAtomicMergingOfDecentralizedValues() {
        var dsetOne = DecentralizedDictionary<String, DecentralizedSet<Int>>()
        dsetOne["1"] = [1,2,3]
        dsetOne["2"] = [3,4,5]
        dsetOne["3"] = [1]

        var dsetTwo = DecentralizedDictionary<String, DecentralizedSet<Int>>()
        dsetTwo["1"] = [1,2,3,4]
        dsetTwo["3"] = [3,4,5]
        dsetTwo["1"] = nil
        dsetTwo["3"]!.insert(6)

        let dsetLHS = dsetOne.merged(with: dsetTwo)
        let dsetRHS = dsetTwo.merged(with: dsetOne)
        XCTAssertEqual(dsetLHS["3"]!.values, [1,3,4,5,6])
        XCTAssertNil(dsetLHS["1"])
        XCTAssertEqual(dsetLHS["2"]!.values, [3,4,5])

        let valuesLHS = dsetLHS.dictionary.values.flatMap({ $0.values }).sorted()
        let valuesRHS = dsetRHS.dictionary.values.flatMap({ $0.values }).sorted()
        XCTAssertEqual(valuesLHS, valuesRHS)
    }

    func testCodable() {
        var dict = DecentralizedDictionary<String, Int>()
        dict["1"] = 1
        dict["2"] = 2
        dict["3"] = 3
        dict["2"] = nil

        let data = try! JSONEncoder().encode(dict)
        let dictd = try! JSONDecoder().decode(type(of: dict), from: data)
        XCTAssertEqual(dict.dictionary, dictd.dictionary)
    }

}
