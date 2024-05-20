//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import DeclarativeTextKit
import XCTest

func textView(_ string: String) -> NSTextView {
    let textView = NSTextView(usingTextLayoutManager: false)
    textView.string = string
    return textView
}

func assertBufferState(
    _ buffer: Buffer,
    _ expectedDescription: String,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file, line: UInt = #line
) {
    XCTAssertEqual(
        MutableStringBuffer(buffer).description,
        expectedDescription,
        message(),
        file: file, line: line
    )
}

func assertThrows<T, E: Error & Equatable>(
    _ expression: @autoclosure () throws -> T,
    error: E,
    file: StaticString = #filePath, line: UInt = #line
) {
    var thrownError: Error?
    XCTAssertThrowsError(
        try expression(),
        file: file, line: line
    ) { thrownError = $0 }

    XCTAssertTrue(
        thrownError is E,
        "Expected error type \(type(of: thrownError)), got of \(E.self)",
        file: file, line: line
    )

    XCTAssertEqual(
        thrownError as? E,
        error,
        file: file, line: line
    )
}
