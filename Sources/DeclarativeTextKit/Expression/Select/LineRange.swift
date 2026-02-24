import Foundation
import TextBuffer

public struct LineRange<Base: BufferRangeExpression> {
    let baseRange: Base

    public init(_ baseRange: Base) {
        self.baseRange = baseRange
    }
}

extension LineRange where Base == NSRange {
    public init(
        location: Int,
        length: Int = 0
    ) {
        self.init(NSRange(location: location, length: length))
    }
}

extension LineRange: BufferRangeExpression {
    public typealias Evaluation = LineRangeInBuffer
    public typealias Failure = Never

    public struct LineRangeInBuffer: BufferRangeEvaluation {
        let buffer: any NSStringBuffer
        let inputRange: BufferRangeEvaluation

        public func bufferRange() throws -> NSRange {
            return try buffer.lineRange(for: inputRange.bufferRange())
        }
    }

    public func evaluate(in buffer: any NSStringBuffer) -> LineRangeInBuffer {
        return LineRangeInBuffer(
            buffer: buffer,
            inputRange: baseRange.evaluate(in: buffer)
        )
    }
}
