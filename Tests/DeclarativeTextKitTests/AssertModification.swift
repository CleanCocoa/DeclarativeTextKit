import XCTest
@testable import DeclarativeTextKit

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

    func evaluate(in buffer: any NSStringBuffer) -> Result<ChangeInLength, BufferAccessFailure> {
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
