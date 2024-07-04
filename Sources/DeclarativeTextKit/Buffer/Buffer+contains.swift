//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation // For inlining isSelectingText as long as Buffer.Range is a typealias

extension Buffer {
    @inlinable @inline(__always)
    public func contains(
        range: Buffer.Range
    ) -> Bool {
        // Selection rules for replacing or deleting text require regular full containment.
        return self.range.contains(range)
    }
}
