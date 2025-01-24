//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension NSRange {
    /// Creates a new range that represents a user's text selection range in a buffer after shifting it by `delta`.
    ///
    /// A negative `delta` that result in the range moving into negative integers clamps values to `0..<Int.max`. Shifting a range so far to the left that its `endLocation` is negative, too, results in an empty selection at the start of the buffer.
    ///
    /// > Invariant: Neither `location` nor `length` go below 0.
    @inlinable @inline(__always)
    public func shifted(by delta: Int) -> NSRange {
        let newLocation = self.location + delta
        return NSRange(
            location: max(0, newLocation),
            length: max(0, self.length + min(0, newLocation))
        )
    }
}
