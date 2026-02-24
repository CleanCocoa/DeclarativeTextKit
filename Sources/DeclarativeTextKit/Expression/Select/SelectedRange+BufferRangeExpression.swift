import Foundation
import TextBuffer

extension AffectedRange: BufferRangeExpression {
    public func evaluate(in buffer: any NSStringBuffer) -> Result<NSRange.NSRangeInBuffer, Never> {
        return .success(NSRange.NSRangeInBuffer(range: value))
    }
}
