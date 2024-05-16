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
