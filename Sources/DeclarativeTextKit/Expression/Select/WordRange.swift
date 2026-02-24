import Foundation
import TextBuffer

public struct WordRange<Base: BufferRangeExpression> {
    let baseRange: Base

    public init(_ baseRange: Base) {
        self.baseRange = baseRange
    }
}

extension WordRange where Base == NSRange {
    public init(
        location: Int,
        length: Int = 0
    ) {
        self.init(NSRange(location: location, length: length))
    }
}

extension WordRange: BufferRangeExpression {
    public typealias Evaluation = WordRangeInBuffer
    public typealias Failure = Never

    public struct WordRangeInBuffer: BufferRangeEvaluation {
        let buffer: any NSStringBuffer
        let inputRange: BufferRangeEvaluation

        public func bufferRange() throws -> NSRange {
            return try buffer.wordRange(for: inputRange.bufferRange())
        }
    }

    public func evaluate(in buffer: any NSStringBuffer) -> WordRangeInBuffer {
        return WordRangeInBuffer(
            buffer: buffer,
            inputRange: baseRange.evaluate(in: buffer)
        )
    }
}
