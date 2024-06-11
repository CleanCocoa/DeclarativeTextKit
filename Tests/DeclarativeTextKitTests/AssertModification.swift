//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import XCTest
@testable import DeclarativeTextKit

/// Test helper to assert the covered content of a selected range during modifications, as a stepping stone towards more complex expressions.
///
/// Example:
///
/// ```swift
/// // Given:
/// print(buffer.content)
/// // => "There is some targeted text in here!"
///
/// // Check that a complex way to select text does what we expect:
/// buffer.evaluate {
///     // ...
///     Select(
///         location: someLocation + anOffset,
///         length: arcaneMaths()
///     ) { selectedRange in
///         Assert(selectedRange, contains: "targeted text")
///         // ...
///     }
///     // ...
/// }
/// ```
struct Assert<RangeExpr: BufferRangeExpression>: Modification, ChainableModification {
    let rangeExpr: RangeExpr
    let expectedContent: String
    let file: StaticString
    let line: UInt

    init(
        _ rangeExpr: RangeExpr,
        contains expectedContent: String,
        file: StaticString = #file, line: UInt = #line
    ) {
        self.rangeExpr = rangeExpr
        self.expectedContent = expectedContent
        self.file = file
        self.line = line
    }

    func evaluate(in buffer: any Buffer) -> Result<ChangeInLength, BufferAccessFailure> {
        do {
            let bufferRange = try rangeExpr.evaluate(in: buffer).bufferRange()
            let content = try buffer.content(in: bufferRange)
            XCTAssertEqual(
                expectedContent,
                content,
                file: file, line: line
            )
            return .success(.empty)
        } catch {
            return .failure(.wrap(error))
        }
    }
}
