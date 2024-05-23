//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

#if os(macOS)
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

open class NSTextViewBuffer: Buffer {
    public let textView: NSTextView

    @inlinable
    open var selectedRange: Buffer.Range {
        get { textView.selectedRange }
        set { textView.selectedRange = newValue }
    }

    @inlinable
    open var range: Buffer.Range { Buffer.Range(location: 0, length: textView.nsMutableString.length) }

    @inlinable
    open var content: Content { textView.nsMutableString as Buffer.Content }

    public init(textView: NSTextView) {
        self.textView = textView
    }

    @usableFromInline
    func wrapAsEditing<T>(_ body: () -> T) -> T {
        textView.textStorage?.beginEditing()
        defer { textView.textStorage?.endEditing() }
        return body()
    }

    @inlinable
    open func lineRange(for range: Buffer.Range) -> Buffer.Range {
        return textView.nsMutableString.lineRange(for: range)
    }

    @inlinable
    open func content(in subrange: UTF16Range) throws -> Buffer.Content {
        guard canRead(in: subrange) else {
            throw BufferAccessFailure.outOfRange(requested: subrange, available: range)
        }

        return textView.nsMutableString.unsafeContent(in: subrange)
    }

    /// Raises an `NSExceptionName` of name `.rangeException` if `location` is out of bounds.
    @inlinable
    open func unsafeCharacter(at location: Buffer.Location) -> Buffer.Content {
        return textView.nsMutableString.unsafeCharacter(at: location)
    }

    @inlinable
    open func insert(_ content: Buffer.Content, at location: Location) throws {
        guard canInsert(at: location) else {
            throw BufferAccessFailure.outOfRange(location: location, available: range)
        }

        wrapAsEditing {
            textView.nsMutableString.insert(content, at: location)
        }
    }

    open func delete(in deletedRange: Buffer.Range) throws {
        guard canDelete(range: deletedRange) else {
            throw BufferAccessFailure.outOfRange(requested: deletedRange, available: range)
        }

        wrapAsEditing {
            textView.nsMutableString.deleteCharacters(in: deletedRange)
        }
    }

    open func replace(range replacementRange: Buffer.Range, with content: Buffer.Content) throws {
        guard canInsert(in: replacementRange) else {
            throw BufferAccessFailure.outOfRange(requested: replacementRange, available: range)
        }

        let selectedRange = self.selectedRange
        defer {
            // Restore the recoverable part of the formerly selected range. By default, when the replaced range overlaps with the text view's selection, it removes the selection and switches to 0-length insertion point.
            textView.setSelectedRange(selectedRange
                .subtracting(replacementRange)
                .shifted(by: replacementRange.location <= selectedRange.location ? length(of: content) : 0))
        }

        wrapAsEditing {
            textView.nsMutableString.replaceCharacters(in: replacementRange, with: content)
        }
    }

    open func modifying<T>(affectedRange: Buffer.Range, _ block: () -> T) throws -> T {
        guard textView.shouldChangeText(in: affectedRange, replacementString: nil) else {
            throw BufferAccessFailure.modificationForbidden(in: affectedRange)
        }
        defer { textView.didChangeText() }

        return wrapAsEditing {
            return block()
        }
    }
}
#endif
