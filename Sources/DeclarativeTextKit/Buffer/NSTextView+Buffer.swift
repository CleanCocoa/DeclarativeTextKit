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
            throw BufferAccessFailure.outOfRange(location: location, available: range)
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
        guard range.isValidInsertionPointLocation(at: location) else {
            throw BufferAccessFailure.outOfRange(location: location, available: range)
        }

        self.nsMutableString.insert(content, at: location)
    }

    public func delete(in deletedRange: Buffer.Range) throws {
        guard range.contains(deletedRange) else {
            throw BufferAccessFailure.outOfRange(requested: deletedRange, available: range)
        }

        self.nsMutableString.deleteCharacters(in: deletedRange)
    }

    public func replace(range replacementRange: Buffer.Range, with content: Buffer.Content) throws {
        guard range.contains(replacementRange) else {
            throw BufferAccessFailure.outOfRange(requested: replacementRange, available: range)
        }

        let selectedRange = (self as Buffer).selectedRange
        defer {
            // Restore the recoverable part of the formerly selected range. By default, when the replaced range overlaps with the text view's selection, it removes the selection and switches to 0-length insertion point.
            self.setSelectedRange(selectedRange
                .subtracting(replacementRange)
                .shifted(by: replacementRange.location <= selectedRange.location ? length(of: content) : 0))
        }
        self.nsMutableString.replaceCharacters(in: replacementRange, with: content)
    }

    public func modifying<T>(affectedRange: Buffer.Range, _ block: () -> T) throws -> T {
        guard self.shouldChangeText(in: affectedRange, replacementString: nil) else {
            throw BufferAccessFailure.modificationForbidden(in: affectedRange)
        }
        defer { self.didChangeText() }
        return block()
    }
}
