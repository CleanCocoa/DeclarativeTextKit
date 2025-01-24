//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import TextBuffer

final class BufferWithSelectionFromStringTests: XCTestCase {
    func testBufferFromPlainString() throws {
        XCTAssertEqual(try makeBuffer("hello\nworld"), MutableStringBuffer("hello\nworld"))
    }

    func testBufferWithSelectedRange() throws {
        let expectedBuffer = MutableStringBuffer("0123456")
        expectedBuffer.selectedRange = .init(location: 1, length: 2)
        XCTAssertEqual(try makeBuffer("0«12»3456"), expectedBuffer)
    }

    func testBufferWithInsertionPoint() throws {
        let expectedBuffer = MutableStringBuffer("0123456")
        expectedBuffer.selectedRange = .init(location: 4, length: 0)
        XCTAssertEqual(try makeBuffer("0123ˇ456"), expectedBuffer)
    }

    func testChangeBuffer() throws {
        let buffer = MutableStringBuffer("hello\nworld")

        try change(buffer: buffer, to: "go«od»bye")
        assertBufferState(buffer, "go«od»bye")

        try change(buffer: buffer, to: "")
        assertBufferState(buffer, "ˇ")
    }
}
