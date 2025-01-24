//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension NSMutableString {
    @usableFromInline
    func unsafeCharacter(at location: Buffer.Location) -> Buffer.Content {
        return unsafeContent(in: self.rangeOfComposedCharacterSequence(at: location))
    }

    @usableFromInline
    func unsafeContent(in range: Buffer.Range) -> Buffer.Content {
        if range.length == 0 {
            // This will always return an empty string, but also raise an exception when the range is out of the string's bounds.
            return self.substring(with: range)
        } else {
            return self.substring(with: self.rangeOfComposedCharacterSequences(for: range))
        }
    }
}
