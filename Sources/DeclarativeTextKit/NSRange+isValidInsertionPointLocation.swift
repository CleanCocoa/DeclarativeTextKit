//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension NSRange {
    /// Unlike `contains(_:)`, also returns `true` *at* the end position, which is not a valid position to read from, but a valid location to append content to.
    ///
    /// - Return: `true` iff `location` is between or equal `lowerBound` or `upperBound`.
    @inlinable @inline(__always)
    public func isValidInsertionPointLocation(at location: Int) -> Bool {
        // Insertion into an empty range at the 0 location, or in a non-empty range at the after-end position represent an appending operation. Both are permissible.
        return location >= 0
            && lowerBound <= location
            && location <= upperBound
    }
}
