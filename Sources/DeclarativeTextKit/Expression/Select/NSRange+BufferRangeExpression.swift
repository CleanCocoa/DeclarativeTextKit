import Foundation
import TextBuffer

extension NSRange: BufferRangeExpression {
    public typealias Evaluation = NSRangeInBuffer
    public typealias Failure = Never

    public struct NSRangeInBuffer: BufferRangeEvaluation {
        let range: NSRange

        public func bufferRange() -> NSRange {
            return range
        }
    }

    public func evaluate(in buffer: any NSStringBuffer) -> NSRangeInBuffer {
        return NSRangeInBuffer(range: self)
    }
}
