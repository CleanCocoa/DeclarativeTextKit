//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension NSRange {
    @usableFromInline
    var hasValidValues: Bool { location >= 0 && length >= 0 }

    /// - Returns: Whether `other` is fully contained in the receiver.
    @inlinable @inline(__always)
    public func contains(_ other: NSRange) -> Bool {
        guard other.hasValidValues else { return false }
        return location <= other.location
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
