//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

#if os(macOS)
import AppKit

extension NSTextView {
    /// `NSString` contents of the receiver avoiding Swift `String` bridging overhead.
    @usableFromInline @inline(__always)
    var nsMutableString: NSMutableString {
        guard let textStorage = self.textStorage else {
            preconditionFailure("NSTextView.textStorage expected to be non-nil")
        }
        return textStorage.mutableString
    }
}

/// Adapter for `NSTextView` to perform ``Buffer`` commands.
///
/// Mutations are performed on the ``textView``'s `NSTextStorage` directly and wrapped in `beginEditing()`/`endEditing()` calls to correctly process changes in `NSTextStorage.processEditing()`. This includes the standard behavior of attribute range fixing and interfacing with the `NSLayoutManager`.
///
/// To group multiple buffer mutations as a single edit, e.g. to delete parts of text in multiple places as one action that coalesces attribute updates, you can either
/// - use the ``Modifying-struct`` command from the DSL, which wraps its mutations in an editing group when applied to an ``NSTextViewBuffer``, or
/// - use the ``wrapAsEditing(_:)`` function directly.
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

    /// Wraps `textView` as the target of all ``Buffer`` related actions.
    public init(textView: NSTextView) {
        self.textView = textView
    }

    /// Wrap the execution of `body` in `beginEditing()`/`endEditing()` calls to group changes inside into a single `NSTextStorage.processEditing()` run.
    @inlinable
    open func wrapAsEditing<T>(_ body: () throws -> T) rethrows -> T {
        textView.textStorage?.beginEditing()
        defer { textView.textStorage?.endEditing() }
        return try body()
    }

    @inlinable
    open func lineRange(for searchRange: Buffer.Range) throws -> Buffer.Range {
        guard contains(range: searchRange) else {
            throw BufferAccessFailure.outOfRange(
                requested: searchRange,
                available: self.range
            )
        }
        return textView.nsMutableString.lineRange(for: searchRange)
    }

    @inlinable
    open func content(in subrange: UTF16Range) throws -> Buffer.Content {
        guard contains(range: subrange) else {
            throw BufferAccessFailure.outOfRange(
                requested: subrange,
                available: self.range
            )
        }

        return textView.nsMutableString.unsafeContent(in: subrange)
    }

    @inlinable
    open func unsafeCharacter(at location: Buffer.Location) -> Buffer.Content {
        // Raises an `NSExceptionName` of name `.rangeException` if `location` is out of bounds.
        return textView.nsMutableString.unsafeCharacter(at: location)
    }

    @inlinable
    open func insert(_ content: Buffer.Content, at location: Location) throws {
        guard contains(range: .init(location: location, length: 0)) else {
            throw BufferAccessFailure.outOfRange(
                location: location,
                available: self.range
            )
        }

        wrapAsEditing {
            textView.nsMutableString.insert(content, at: location)
        }
    }

    @inlinable
    open func delete(in deletedRange: Buffer.Range) throws {
        guard contains(range: deletedRange) else {
            throw BufferAccessFailure.outOfRange(
                requested: deletedRange,
                available: self.range
            )
        }

        wrapAsEditing {
            textView.nsMutableString.deleteCharacters(in: deletedRange)
        }
    }

    @inlinable
    open func replace(range replacementRange: Buffer.Range, with content: Buffer.Content) throws {
        guard contains(range: replacementRange) else {
            throw BufferAccessFailure.outOfRange(requested: replacementRange, available: self.range)
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

    @inlinable
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
