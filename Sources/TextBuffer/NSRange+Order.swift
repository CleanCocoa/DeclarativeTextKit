//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension NSRange {
    public enum Order {
        case strictlyBefore, intersects, strictlyAfter
    }

    @inlinable
    public func ordered(comparedTo other: NSRange) -> Order {
        // Remember: `upperBound` is the location right after the range, i.e. not included.
        // So `NSRange(location: 10, length: 5)` does not include `15`, and `15` would be .strictlyAfter
        if self.upperBound <= other.lowerBound { return .strictlyBefore }
        // We could change `>=` to `>` and thus `.strictlyAfter` to `.strictlyAfterOrUpperBoundsTouching` to treat
        // as intersection when the user inserts right before the receiver. E.g. a token range (0...10), and an
        // edited range of (0...0) with an insertion here correctly treats the token range as `.strictlyAfter`.
        // But in trying to reuse the range, which will be nudged to `(1...11)`, the range will effectively be
        // skipped in `Highlighter.didPreviouslyHighlight(_:)` because the range that's going to be checked
        // is `(0...11)` and that doesn't exist.
        if self.lowerBound >= other.upperBound { return .strictlyAfter }
        return .intersects
    }
}
