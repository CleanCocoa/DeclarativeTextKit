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
    /// Unlike `NSString.rangeOfCharacter(from:options:range:)`, handles Emoji as composed UTF-16 character sequences properly.
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
        guard range.length > 0 else { return nil }

        var nextLocation: Buffer.Location? = {
            let nextLocation = switch direction {
            case .upstream: range.endLocation - 1 // It's fine to not subtract a composed character sequence's length here since we'll fetch that in the loop.
            case .downstream: range.location
            }
            guard range.contains(nextLocation) else { return nil }
            return nextLocation
        }()

        func advanced(location: Buffer.Location) -> Buffer.Location? {
            switch direction {
            case .upstream:
                guard location > range.location else { return nil }
                return self.rangeOfComposedCharacterSequence(at: location - 1).location
            case .downstream:
                guard location < range.endLocation - 1 else { return nil }
                return self.rangeOfComposedCharacterSequence(at: location).endLocation
            }
        }

        while let location = nextLocation,
              range.contains(location) {
            let characterSequenceRange = self.rangeOfComposedCharacterSequence(at: location)
            let characterSequence = self.substring(with: characterSequenceRange) as NSString

            if characterSet.contains(characterSequence: characterSequence) {
                return switch direction {
                case .upstream: characterSequenceRange.endLocation
                case .downstream: characterSequenceRange.location
                }
            }

            nextLocation = advanced(location: location)
        }

        return nil
    }
}

extension CharacterSet {
    @inlinable
    func contains(characterSequence: NSString) -> Bool {
        return characterSequence.rangeOfCharacter(from: self) == NSRange(location: 0, length: characterSequence.length)
    }
}
