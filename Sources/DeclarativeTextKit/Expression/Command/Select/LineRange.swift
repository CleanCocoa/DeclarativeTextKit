//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public struct LineRange {
    let inputRange: Buffer.Range

    public init(_ inputRange: Buffer.Range) {
        self.inputRange = inputRange
    }
}

extension LineRange: BufferRangeExpression {
    public typealias Evaluation = LineRangeInBuffer
    public typealias Failure = Never

    public struct LineRangeInBuffer: BufferRangeEvaluation {
        let buffer: Buffer
        let inputRange: Buffer.Range

        public func bufferRange() -> Buffer.Range {
            return buffer.lineRange(for: inputRange)
        }
    }

    public func evaluate(in buffer: Buffer) -> LineRangeInBuffer {
        return LineRangeInBuffer(buffer: buffer, inputRange: inputRange)
    }
}
