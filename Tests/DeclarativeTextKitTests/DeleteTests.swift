//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

final class DeleteTests: XCTestCase {
    func testDeleteOnce() {
        let buffer: Buffer = MutableStringBuffer("Hello, World!")
        
        let changeInLength = Delete(1..<8).evaluate(in: buffer)

        XCTAssertEqual(changeInLength, -7)
        XCTAssertEqual(buffer.content, "Horld!")
    }
}
