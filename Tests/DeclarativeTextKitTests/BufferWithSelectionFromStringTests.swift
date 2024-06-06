//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

final class BufferWithSelectionFromStringTests: XCTestCase {
    func testBufferFromPlainString() throws {
        XCTAssertEqual(try buffer("hello\nworld"), MutableStringBuffer("hello\nworld"))
    }

    func testBufferWithSelectedRange() throws {
        let expectedBuffer = MutableStringBuffer("0123456")
        expectedBuffer.selectedRange = .init(location: 1, length: 2)
        XCTAssertEqual(try buffer("0{12}3456"), expectedBuffer)
    }

    func testBufferWithInsertionPoint() throws {
        let expectedBuffer = MutableStringBuffer("0123456")
        expectedBuffer.selectedRange = .init(location: 4, length: 0)
        XCTAssertEqual(try buffer("0123{^}456"), expectedBuffer)
    }
}
