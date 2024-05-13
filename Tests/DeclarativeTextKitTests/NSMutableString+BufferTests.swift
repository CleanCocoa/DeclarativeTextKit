//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

final class NSMutableString_BufferTests: XCTestCase {
    func testRange() {
        XCTAssertEqual((NSMutableString("") as Buffer).range,
                       .init(location: 0, length: 0))
        XCTAssertEqual((NSMutableString("a") as Buffer).range,
                       .init(location: 0, length: 1))
        XCTAssertEqual((NSMutableString("hello\n\nworld") as Buffer).range,
                       .init(location: 0, length: 12))
        XCTAssertEqual((NSMutableString("💃🐞🏴‍☠️") as Buffer).range,
                       .init(location: 0, length: 9))
    }

    func testCharacterAtLocation() {
        let buffer = NSMutableString("bug 🐞")
        let characters = (0..<5).map { buffer.unsafeCharacter(at: $0) }
        XCTAssertEqual(characters, ["b", "u", "g", " ", "🐞"])
    }

    func testInsertContentAtLocation() {
        let buffer = NSMutableString("hi")

        buffer.insert("🐞 bug", at: 1)

        XCTAssertEqual(buffer, "h🐞 bugi")
    }

    func testSelectedRange() {
        let buffer = NSMutableString("hi")

        // Precondition
        XCTAssertEqual(buffer.selectedRange, .init(location: NSNotFound, length: 0))

        buffer.select(.init(location: 1, length: 1))

        // Postcondition
        XCTAssertEqual(buffer.selectedRange, .init(location: NSNotFound, length: 0))
    }
}
