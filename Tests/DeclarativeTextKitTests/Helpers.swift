//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import DeclarativeTextKit
import XCTest

#if os(macOS)
import AppKit

func textView(_ string: String) -> NSTextViewBuffer {
    let textView = NSTextView(usingTextLayoutManager: false)
    textView.string = string
    return NSTextViewBuffer(textView: textView)
}
#endif

func assertBufferState(
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
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath, line: UInt = #line
) {
    var thrownError: Error?
    XCTAssertThrowsError(
        try expression(),
        file: file, line: line
    ) { thrownError = $0 }

    guard let thrownError else {
        XCTFail(
            "Expected to throw error."
            + (message().isEmpty ? "" : " \(message())"),
            file: file, line: line
        )
        return
    }

    guard let thrownError = thrownError as? BufferAccessFailure else {
        XCTFail(
            "Expected error type \(BufferAccessFailure.self), got of \(type(of: thrownError))."
            + (message().isEmpty ? "" : "  \(message())"),
            file: file, line: line
        )
        return
    }

    XCTAssertEqual(
        error.debugDescription,
        "\(thrownError)",
        message(),
        file: file, line: line
    )
}

extension Buffer {
    @discardableResult
    func evaluate(
        location: Buffer.Location,
        length: Buffer.Length,
        @ModificationBuilder _ expression: (AffectedRange) throws -> ModificationSequence
    ) throws -> ChangeInLength {
        return try self.evaluate(
            in: Buffer.Range(
                location: location,
                length: length
            ),
            expression
        )
    }
}
