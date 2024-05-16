//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension NSRange {

    /// A new range that represents a part of a text buffer, left over after removing `other` from the buffer.
    ///
    /// Reduces the `length` by the intersection of both ranges, and shifts the `location` left (towards 0) by how much was removed from before the start.
    func subtracting(_ other: NSRange) -> NSRange {
        guard self.location != NSNotFound else { return .notFound }
        guard other.location != NSNotFound else { return self }

        let leftShift = if self.location > other.location {
            // Compute the length from other.location up to and including self.location, but no further (i.e. the difference of both ranges to the left)
            min(other.endLocation, self.location) - other.location
        } else {
            0
        }
        let newLocation = max(0, self.location - leftShift)
        let newLength = self.length - (self.intersection(other)?.length ?? 0)
        return NSRange(
            location: newLocation,
            length: newLength
        )
    }
}
