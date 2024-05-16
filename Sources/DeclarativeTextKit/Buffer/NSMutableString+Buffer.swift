//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension NSMutableString: Buffer {
    public var range: Buffer.Range { Buffer.Range(location: 0, length: self.length) }

    public var content: Content { self as Buffer.Content }

    /// Raises an `NSExceptionName` of name `.rangeException` if `location` is out of bounds.
    public func unsafeCharacter(at location: UTF16Offset) -> Buffer.Content {
        return self.substring(with: rangeOfComposedCharacterSequence(at: location))
    }

    public func select(_ range: Buffer.Range) {
        // no op
    }

    public var selectedRange: Buffer.Range {
        return .init(location: NSNotFound, length: 0)
    }

    /// Raises an `NSExceptionName` of name `.rangeException` if any part of `range` lies beyond the end of the buffer.
    public func delete(in range: Buffer.Range) {
        self.deleteCharacters(in: range)
    }

    public func replace(range: Buffer.Range, with content: Buffer.Content) {
        self.replaceCharacters(in: range, with: content)
    }
}
