//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension NSRange {
    @inlinable @inline(__always)
    func expanded(
        to other: NSRange,
        direction: StringTraversalDirection
    ) -> NSRange {
        precondition(other.location <= self.location && other.endLocation >= self.endLocation, "Expansion requires other range to be larger")

        let startLocation = switch direction {
        case .upstream: other.location
        case .downstream: self.location
        }

        let endLocation = switch direction {
        case .upstream: self.endLocation
        case .downstream: other.endLocation
        }

        return NSRange(
            startLocation: startLocation,
            endLocation: endLocation
        )
    }
}
