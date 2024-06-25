//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension NSRange {
    /// - Returns: Subrange that starts after `other`.
    @inlinable
    func suffix(after other: NSRange) -> NSRange {
        precondition(self.location <= other.endLocation && self.endLocation >= other.endLocation, "Suffix requires range to start right after or encompass other range")

        return NSRange(
            startLocation: other.endLocation,
            endLocation: self.endLocation
        )
    }
}
