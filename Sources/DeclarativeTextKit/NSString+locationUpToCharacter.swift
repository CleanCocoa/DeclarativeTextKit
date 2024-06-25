//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

public enum Direction {
    /// Left-to-right or towards-the-end search in a string.
    case downstream
    /// Right-to-left or towards-the-beginning search in a string.
    case upstream
}

extension NSString {
    /// Finds and returns the location adjacent to the first character from `characterSet` found in the substring `range` in `direction`.
    ///
    /// Use this to find an insertion point _next to_ a match to insert text into.
    ///
    /// ## Example of 'adjacency'
    ///
    /// To finding location _up to_ a character from `CharacterSet.punctuationCharacters` in this piece of text:
    ///
    ///     "a (test) text"
    ///
    /// will be one of the following, with the location denoted by `ˇ`:
    ///
    ///     "a ˇ(test) text"  // Downstream / from left to right
    ///     "a (test)ˇ text"  // Upstream / from right to left
    @inlinable
    public func locationUpToCharacter(
        from characterSet: CharacterSet,
        direction: Direction,
        in range: NSRange
    ) -> Buffer.Location? {
        var options: NSString.CompareOptions = []
        if direction == .upstream { options.insert(.backwards) }

        let result = rangeOfCharacter(from: characterSet, options: options, range: range)

        if result == .notFound { return nil }

        return switch direction {
        case .upstream: result.endLocation
        case .downstream: result.location
        }
    }
}
