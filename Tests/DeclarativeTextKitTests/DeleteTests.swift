//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

final class DeleteTests: XCTestCase {
    func testDeleteOnce() throws {
        let buffer: Buffer = MutableStringBuffer("Hello, World!")
        
        let changeInLength = try Delete(1..<8).evaluate(in: buffer)

        XCTAssertEqual(changeInLength.delta, -7)
        XCTAssertEqual(buffer.content, "Horld!")
    }
}
