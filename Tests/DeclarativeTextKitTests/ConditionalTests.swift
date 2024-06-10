//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

final class ConditionalTests: XCTestCase {
    func testConditionalSequences() throws {
        let buffer = try makeBuffer("Helloˇ")

        var collectedStates: [String] = []
        for i in (0 ..< 5).reversed() {
            try buffer.evaluate(location: i, length: 1) { charRange in
                If(i % 2 == 0) {
                    Modifying(charRange) { charRange in
                        Delete(charRange)
                    }
                    // This is redundant but shows that the compiler/DSL accepts multiple expressions in the conditional
                    Select(i)
                }
                // This produces a more interesting test output, moving the insertion point
                Select(i)
            }
            collectedStates.append(buffer.description)
        }

        XCTAssertEqual(collectedStates, [
            "Hellˇ",
            "Helˇl",
            "Heˇl",
            "Hˇel",
            "ˇel",
        ])
    }

    func testConditionalBindingSequences() throws {
        let buffer = try makeBuffer("Helloˇ")

        var collectedStates: [String] = []
        for part in [nil, " world", nil, nil, "!"] {
            try buffer.evaluate { fullRange in
                IfLet (part) { part in
                    Modifying(fullRange) { range in
                        Insert(range.endLocation) { part }
                    }
                }
            }
            collectedStates.append(buffer.description)
        }

        XCTAssertEqual(collectedStates, [
            "Helloˇ",
            "Hello worldˇ",
            "Hello worldˇ",
            "Hello worldˇ",
            "Hello world!ˇ",
        ])
    }

    func testIfElseSequence() throws {
        let buffer = try makeBuffer("Text: ˇ")

        let letters = Array("abcde")
        let numbers = Array("12345")

        var collectedStates: [String] = []
        for i in (0 ..< 5) {
            try buffer.evaluate(
                location: length(of: "Text: ") + i,
                length: 0
            ) { charRange in
                If (i % 2 == 0) {
                    Modifying(charRange) { charRange in
                        Insert(charRange.location) { String(letters[i]) }
                    }
                } else: {
                    Modifying(charRange) { charRange in
                        Insert(charRange.location) { String(numbers[i]) }
                    }
                }
                Select(charRange)
            }
            collectedStates.append(buffer.description)
        }

        XCTAssertEqual(collectedStates, [
            "Text: «a»",
            "Text: a«2»",
            "Text: a2«c»",
            "Text: a2c«4»",
            "Text: a2c4«e»",
        ])
    }
}
