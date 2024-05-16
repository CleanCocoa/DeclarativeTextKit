//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

final class UseCaseTests: XCTestCase {
    func testWrapSelectionInLines() {
        let buffer: MutableStringBuffer = """
# Heading

Text here. It is
not a lot of text.

But it is nice.

"""
        let selectedRange = Buffer.Range(location: 20, length: 11) // From line 3, "here", up to the next line.

        let commandCascade = Select(LineRange(selectedRange)) { lineRange in
            // Wrap selected text in code block
            Modifying(lineRange) { rangeToWrap in
                Insert(rangeToWrap.location) { Line("```") }
                Insert(rangeToWrap.endLocation) { Line("```") }
            }

            // Move insertion point to the position after the opening backticks
            Select(lineRange.location + length(of: "```"))
        }
        commandCascade(buffer: buffer)

        XCTAssertEqual(buffer.selectedRange, Buffer.Range(location: 14, length: 0))

        buffer.insert("raw")  // Simulate typing at the selection

        XCTAssertEqual(buffer.description, """
# Heading

```raw{^}
Text here. It is
not a lot of text.
```
But it is nice.

""")
    }
}
