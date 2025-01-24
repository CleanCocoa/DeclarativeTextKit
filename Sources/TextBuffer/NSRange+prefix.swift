//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension NSRange {
    /// - Returns: Subrange that ends before `other`.
    @inlinable
    func prefix(upTo other: NSRange) -> NSRange {
        return prefix(upTo: other.location)
    }

    /// - Returns: Subrange that ends before `location`.
    @inlinable
    func prefix(upTo location: Int) -> NSRange {
        precondition(self.location <= location && self.endLocation >= location, "Prefix requires range to reach up to or encompass location")

        return NSRange(
            startLocation: self.location,
            endLocation: location
        )
    }
}
