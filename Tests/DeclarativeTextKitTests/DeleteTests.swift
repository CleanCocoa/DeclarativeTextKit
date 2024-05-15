//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
import DeclarativeTextKit

final class DeleteTests: XCTestCase {
    var mutableString: NSMutableString = "Hello, World!"

    func testDeleteOnce() {
        let changeInLength = Delete(1..<8).apply(to: mutableString)

        XCTAssertEqual(changeInLength, -7)
        XCTAssertEqual(mutableString, "Horld!")
    }
}
