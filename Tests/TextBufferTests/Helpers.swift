//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import TextBuffer

// Re-export so we don't have to import all the helpers everywhere.
@_exported import TextBufferTesting

#if os(macOS)
import AppKit

func textView(_ string: String) -> NSTextViewBuffer {
    let textView = NSTextView(usingTextLayoutManager: false)
    textView.string = string
    return NSTextViewBuffer(textView: textView)
}
#endif

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
