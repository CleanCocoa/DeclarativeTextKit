//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

final class ConditionalTests: XCTestCase {
    func testConditionalSequences() throws {
        let buffer = try makeBuffer("Helloˇ")

        var collectedStates: [String] = []
        for i in (0 ..< 5).reversed() {
            try buffer.evaluate {
                if i % 2 == 0 {
                    Modifying(SelectedRange(location: i, length: 1)) { charRange in
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
}
