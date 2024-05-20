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
    public var range: Buffer.Range { Buffer.Range(location: 0, length: self.nsMutableString.length) }

    @inlinable
    public var content: Content { self.nsMutableString as Buffer.Content }

    @inlinable
    public func lineRange(for range: Buffer.Range) -> Buffer.Range {
        return self.nsMutableString.lineRange(for: range)
    }

    @inlinable
    public func character(at location: Location) throws -> Buffer.Content {
        guard range.contains(location) else {
            throw LocationOutOfBounds(location: location, bounds: range)
        }
        return self.nsMutableString.unsafeCharacter(at: location)
    }

    /// Raises an `NSExceptionName` of name `.rangeException` if `location` is out of bounds.
    @inlinable
    public func unsafeCharacter(at location: Buffer.Location) -> Buffer.Content {
        return self.nsMutableString.unsafeCharacter(at: location)
    }

    @inlinable
    public func insert(_ content: Buffer.Content, at location: Location) throws {
        // Insertion into an empty range at the 0 location, or in a non-empty range at the after-end position equal appending and are permitted.
        guard range.lowerBound <= location,
              location <= range.upperBound
        else {
            throw LocationOutOfBounds(location: location, bounds: range)
        }

        self.nsMutableString.insert(content, at: location)
    }

    /// Raises an `NSExceptionName` of name `.rangeException` if any part of `range` lies beyond the end of the buffer.
    public func delete(in range: Buffer.Range) {
        self.nsMutableString.deleteCharacters(in: range)
    }

    public func replace(range: Buffer.Range, with content: Buffer.Content) {
        let selectedRange = (self as Buffer).selectedRange
        defer {
            // Restore the recoverable part of the formerly selected range. By default, when the replaced range overlaps with the text view's selection, it removes the selection and switches to 0-length insertion point.
            self.setSelectedRange(selectedRange
                .subtracting(range)
                .shifted(by: length(of: content)))
        }
        self.nsMutableString.replaceCharacters(in: range, with: content)
    }
}
