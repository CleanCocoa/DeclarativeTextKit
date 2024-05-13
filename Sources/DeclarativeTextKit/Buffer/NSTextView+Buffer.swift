//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

extension NSTextView {
    /// `NSString` contents of the receiver without briding overhead.
    @usableFromInline
    var nsMutableString: NSMutableString {
        guard let textStorage = self.textStorage else {
            preconditionFailure("NSTextView.textStorage expected to be non-nil")
        }
        return textStorage.mutableString
    }
}

extension NSTextView: Buffer {
    @inlinable
    public var range: Buffer.Range { self.nsMutableString.range }

    @inlinable
    public func lineRange(for range: Buffer.Range) -> Buffer.Range {
        return self.nsMutableString.lineRange(for: range)
    }

    /// Raises an `NSExceptionName` of name `.rangeException` if `location` is out of bounds.
    @inlinable
    public func unsafeCharacter(at location: UTF16Offset) -> Buffer.Content {
        return self.nsMutableString.unsafeCharacter(at: location)
    }

    @inlinable
    public func insert(_ content: Content, at location: Location) {
        self.nsMutableString.insert(content, at: location)
    }

    @inlinable
    public func select(_ range: Buffer.Range) {
        self.setSelectedRange(range)
    }
}
