//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension NSRange {
    /// - Returns: Subrange that ends before `other`.
    @inlinable
    func prefix(upTo other: NSRange) -> NSRange {
        precondition(self.location <= other.location && self.endLocation >= other.location, "Prefix requires range to reach up to or encompass other range")

        return NSRange(
            startLocation: self.location,
            endLocation: other.location
        )
    }
}
