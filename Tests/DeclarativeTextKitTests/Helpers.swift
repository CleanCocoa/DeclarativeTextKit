//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import DeclarativeTextKit
import XCTest

func textView(_ string: String) -> NSTextViewBuffer {
    let textView = NSTextView(usingTextLayoutManager: false)
    textView.string = string
    return NSTextViewBuffer(textView: textView)
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

    guard let thrownError else {
        XCTFail(
            "Expected to throw error",
            file: file, line: line
        )
        return
    }

    guard let thrownError = thrownError as? E else {
        XCTFail(
            "Expected error type \(E.self), got of \(type(of: thrownError))",
            file: file, line: line
        )
        return
    }

    XCTAssertEqual(
        thrownError,
        error,
        file: file, line: line
    )
}

func assertThrows<T>(
    _ expression: @autoclosure () throws -> T,
    error: BufferAccessFailure,
    file: StaticString = #filePath, line: UInt = #line
) {
    var thrownError: Error?
    XCTAssertThrowsError(
        try expression(),
        file: file, line: line
    ) { thrownError = $0 }

    guard let thrownError else {
        XCTFail(
            "Expected to throw error",
            file: file, line: line
        )
        return
    }

    guard let thrownError = thrownError as? BufferAccessFailure else {
        XCTFail(
            "Expected error type \(BufferAccessFailure.self), got of \(type(of: thrownError))",
            file: file, line: line
        )
        return
    }

    XCTAssertEqual(
        error.debugDescription,
        "\(thrownError)",
        file: file, line: line
    )
}
