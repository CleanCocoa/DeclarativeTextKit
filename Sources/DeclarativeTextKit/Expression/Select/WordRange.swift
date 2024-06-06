//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

/// A ``Buffer/Range`` finder that expands its input range to word boundaries.
///
/// Word boundaries are detected according to the rules of ``Buffer/wordRange(for:)``.
public struct WordRange<Base: BufferRangeExpression> {
    let baseRange: Base

    public init(_ baseRange: Base) {
        self.baseRange = baseRange
    }
}

extension WordRange: BufferRangeExpression {
    public typealias Evaluation = WordRangeInBuffer
    public typealias Failure = Never

    public struct WordRangeInBuffer: BufferRangeEvaluation {
        let buffer: Buffer
        let inputRange: BufferRangeEvaluation

        public func bufferRange() throws -> Buffer.Range {
            return try buffer.wordRange(for: inputRange.bufferRange())
        }
    }

    public func evaluate(in buffer: Buffer) -> WordRangeInBuffer {
        return WordRangeInBuffer(
            buffer: buffer,
            // Obtain the `baseRange`'s evaluation lazily to be compatible with `SelectedRange` changing during the block's evaluation instead of during its declaration.
            inputRange: baseRange.evaluate(in: buffer)
        )
    }
}
