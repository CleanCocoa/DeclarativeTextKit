//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension AffectedRange: BufferRangeExpression {
    public func evaluate(in buffer: Buffer) -> Result<NSRange.NSRangeInBuffer, Never> {
        return .success(NSRange.NSRangeInBuffer(range: value))
    }
}
