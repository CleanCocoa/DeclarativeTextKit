//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension NSRange {
    /// - Returns: Whether `other` is fully contained in the receiver.
    @inlinable @inline(__always)
    public func contains(_ other: NSRange) -> Bool {
        return self.intersection(other) == other
    }
}
