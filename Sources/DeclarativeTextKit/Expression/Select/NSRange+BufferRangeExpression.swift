//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension NSRange: BufferRangeExpression {
    public typealias Evaluation = NSRangeInBuffer
    public typealias Failure = Never

    public struct NSRangeInBuffer: BufferRangeEvaluation {
        let range: Buffer.Range

        public func bufferRange() -> Buffer.Range {
            return range
        }
    }

    public func evaluate(in buffer: Buffer) -> NSRangeInBuffer {
        return NSRangeInBuffer(range: self)
    }
}
