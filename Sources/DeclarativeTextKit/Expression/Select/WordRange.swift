//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

/// A ``Buffer/Range`` finder that expands its input range to word boundaries.
///
/// Word boundaries are detected according to the rules of ``Buffer/wordRange(for:)``.
public struct WordRange {
    let inputRange: Buffer.Range

    public init(_ inputRange: Buffer.Range) {
        self.inputRange = inputRange
    }
}

extension WordRange: BufferRangeExpression {
    public typealias Evaluation = WordRangeInBuffer
    public typealias Failure = Never

    public struct WordRangeInBuffer: BufferRangeEvaluation {
        let buffer: Buffer
        let inputRange: Buffer.Range

        public func bufferRange() throws -> Buffer.Range {
            return try buffer.wordRange(for: inputRange)
        }
    }

    public func evaluate(in buffer: Buffer) -> WordRangeInBuffer {
        return WordRangeInBuffer(buffer: buffer, inputRange: inputRange)
    }
}
