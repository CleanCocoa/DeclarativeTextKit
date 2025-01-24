//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import TextBuffer

public func assertBufferState(
    _ buffer: Buffer,
    _ expectedDescription: String,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file, line: UInt = #line
) {
    XCTAssertEqual(
        MutableStringBuffer(wrapping: buffer).description,
        expectedDescription,
        message(),
        file: file, line: line
    )
}
