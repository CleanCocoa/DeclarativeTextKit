//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

public enum StringTraversalDirection {
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
        direction: StringTraversalDirection,
        in range: NSRange
    ) -> Buffer.Location? {
        var result: Buffer.Location?

        var options: NSString.EnumerationOptions = [.byComposedCharacterSequences]
        if direction == .upstream {
            options.insert(.reverse)
        }
        self.enumerateSubstrings(in: range, options: options) { characterSequence, characterSequenceRange, enclosingRange, stop in
            guard let characterSequence = characterSequence as? NSString
            else { assertionFailure(); return }
            if characterSet.contains(characterSequence: characterSequence) {
                result = switch direction {
                case .upstream: characterSequenceRange.endLocation
                case .downstream: characterSequenceRange.location
                }
                stop.pointee = true
            }
        }

        return result
    }
}

extension CharacterSet {
    @inlinable
      func contains(characterSequence: NSString) -> Bool {
        return characterSequence.rangeOfCharacter(from: self) == NSRange(location: 0, length: characterSequence.length)
    }
}
