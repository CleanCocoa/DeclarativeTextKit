//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation // For inlining isSelectingText as long as Buffer.Range is a typealias

extension Buffer {
    @inlinable @inline(__always)
    public func contains(
        range: Buffer.Range
    ) -> Bool {
        return self.range.contains(range)
    }
}
