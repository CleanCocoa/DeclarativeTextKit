//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension NSRange {
    /// Creates a new range that represents a user's text selection range in a buffer after enlarging or shrinking by `delta`.
    ///
    /// > Invariant: `length` never goes below `0`.
    ///
    /// > Warning: Does not protect against integer overlow.
    public func resized(by delta: Int) -> NSRange {
        assert(length / 2 + delta / 2 < Int.max / 2,
               "Adding `delta` (\(delta)) to `length` (\(length)) would overflow `Int.max` (\(Int.max))")
        return NSRange(
            location: self.location,
            length: max(0, self.length + delta)
        )
    }
}
