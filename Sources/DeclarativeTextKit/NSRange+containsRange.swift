//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension NSRange {
    /// - Returns: Whether `other` is fully contained in the receiver.
    @inlinable @inline(__always)
    public func contains(_ other: NSRange) -> Bool {
        if self == other { return true }
        return location <= other.location
            && endLocation > other.location  // Exclude at-end location for empty ranges.
            && endLocation >= other.endLocation
    }

    /// - Returns: Whether `other` is fully contained in the receiver, false if `other` is nil.
    @inlinable @inline(__always)
    @_disfavoredOverload
    public func contains(_ other: NSRange?) -> Bool {
        guard let other else { return false }
        return contains(other)
    }
}
