//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import TextBuffer

/// A ``Buffer/Range`` finder that expands its input range to full lines.
///
/// Word boundaries are detected according to the rules of ``Buffer/lineRange(for:)``.
public struct LineRange<Base: BufferRangeExpression> {
    let baseRange: Base

    public init(_ baseRange: Base) {
        self.baseRange = baseRange
    }
}

extension LineRange where Base == Buffer.Range {
    public init(
        location: Buffer.Location,
        length: Buffer.Length = 0
    ) {
        self.init(Buffer.Range(location: location, length: length))
    }
}

extension LineRange: BufferRangeExpression {
    public typealias Evaluation = LineRangeInBuffer
    public typealias Failure = Never

    public struct LineRangeInBuffer: BufferRangeEvaluation {
        let buffer: Buffer
        let inputRange: BufferRangeEvaluation

        public func bufferRange() throws -> Buffer.Range {
            return try buffer.lineRange(for: inputRange.bufferRange())
        }
    }

    public func evaluate(in buffer: Buffer) -> LineRangeInBuffer {
        return LineRangeInBuffer(
            buffer: buffer,
            // Obtain the `baseRange`'s evaluation lazily to be compatible with `AffectedRange` changing during the block's evaluation instead of during its declaration.
            inputRange: baseRange.evaluate(in: buffer)
        )
    }
}
