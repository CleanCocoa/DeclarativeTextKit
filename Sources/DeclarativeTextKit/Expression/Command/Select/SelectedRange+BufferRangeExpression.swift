//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension SelectedRange: BufferRangeExpression {
    public func evaluate(in buffer: Buffer) -> NSRange.NSRangeInBuffer {
        return NSRange.NSRangeInBuffer(range: value)
    }
}
