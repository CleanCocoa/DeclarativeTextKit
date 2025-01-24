//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension NSRange {
    /// - Returns: Subrange that starts after `other`.
    @inlinable
    func suffix(after other: NSRange) -> NSRange {
        return suffix(after: other.endLocation)
    }

    /// - Returns: Subrange that starts after `location`.
    @inlinable
    func suffix(after location: Int) -> NSRange {
        precondition(self.location <= location && self.endLocation >= location, "Suffix requires range to start right after or encompass location")

        return NSRange(
            startLocation: location,
            endLocation: self.endLocation
        )
    }
}
