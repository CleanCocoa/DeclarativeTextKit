//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

/// A text buffer contains UTF16 characters.
public protocol Buffer: AnyObject {
    typealias Location = UTF16Offset
    typealias Length = UTF16Length
    typealias Range = UTF16Range
    typealias Content = String

    var content: Content { get }

    /// Full range of ``content``.
    var range: Range { get }

    /// Selected range. Equals `{0,0}` in case of empty content.
    var selectedRange: Range { get set }

    /// Location where text would next be inserted at if the user types.
    ///
    /// In case of an active selection defaults to the start of the selection.
    var insertionLocation: Location { get set }

    /// Whether the buffer would insert text at an insertion point additively, or whether it is in selection mode and insertion would overwrite text.
    var isSelectingText: Bool { get }

    /// Change selected range in receiver.
    func select(_ range: Range)

    /// Expanded `searchRange` to conver whole lines. Chained calls returns the same line range, i.e. does not expand line by line.
    ///
    /// Quoting from `Foundation.NSString.lineRange(for:)` (as of 2024-06-04, Xcode 15.4):
    ///
    /// > NSString: A line is delimited by any of these characters, the longest possible sequence being preferred to any shorter:
    /// >
    /// > - `U+000A` Unicode Character 'LINE FEED (LF)' (`\n`)
    /// > - `U+000D` Unicode Character 'CARRIAGE RETURN (CR)' (`\r`)
    /// > - `U+0085` Unicode Character 'NEXT LINE (NEL)'
    /// > - `U+2028` Unicode Character 'LINE SEPARATOR'
    /// > - `U+2029` Unicode Character 'PARAGRAPH SEPARATOR'
    /// > - `\r\n`, in that order (also known as `CRLF`)
    func lineRange(for searchRange: Range) throws -> Range

    /// Expanded `baseRange` to conver whole words. Chained calls returns the same line range, i.e. does not expand line by line.
    /// - Throws: ``BufferAccessFailure`` if `subrange` exceeds ``range``.
    func wordRange(for searchRange: Range) throws -> Range

    /// - Returns: A character-wide slice of ``content`` at `location`.
    /// - Throws: ``BufferAccessFailure`` if `location` exceeds ``range``.
    func character(at location: Location) throws -> Content

    /// - Returns: A slice of ``content`` in `range`.
    /// - Throws: ``BufferAccessFailure`` if `subrange` exceeds ``range``.
    func content(in subrange: Buffer.Range) throws -> Content

    /// Returns a character-wide slice of ``content`` at `location`.
    ///
    /// Useful for unchecked access to buffer contents e.g. in loops, requiring checks on the caller's side.
    ///
    /// > Warning: Raises an exception if `location` is out of bounds.
    func unsafeCharacter(at location: Location) -> Content

    /// Inserts `content` at `location` into the buffer, not affecting the typing location of ``selectedRange`` in the process.
    ///
    /// - Throws: ``BufferAccessFailure`` if `location` exceeds ``range``.
    func insert(_ content: Content, at location: Location) throws

    /// Inserts `content` like typing at the current typing location of ``selectedRange``.
    ///
    /// This replaces any existing selected text. The ``selectedRange`` is modified in the process:
    ///
    /// - inserting text at the insertion point moves the insertion point by `length(of: content)`,
    /// - replacing text moves the insertion point to the end of the inserted text (exiting the selection mode).
    func insert(_ content: Content) throws

    /// Deletes content from `deletedRange`.
    ///
    /// Deletion does not move the typing location of ``selectedRange`` to `deletedRange` in the process, but deleting from before ``insertionLocation-4ey6j`` will move the insertion further towards the beginning of the text.
    ///
    /// - Throws: ``BufferAccessFailure`` if `deletedRange` exceeds ``range``.
    func delete(in deletedRange: Range) throws

    /// - Throws: ``BufferAccessFailure`` if `replacementRange` exceeds ``range``.
    func replace(range replacementRange: Range, with content: Content) throws

    /// Wrapping changes inside `block` in a modification request to bundle updates.
    ///
    /// - Throws: ``BufferAccessFailure`` if changes to `affectedRange` are not permitted.
    func modifying<T>(affectedRange: Range, _ block: () -> T) throws -> T
}

import Foundation // For inlining isSelectingText as long as Buffer.Range is a typealias

extension Buffer {
    @inlinable @inline(__always)
    public var isSelectingText: Bool { selectedRange.length > 0 }

    @inlinable @inline(__always)
    public var insertionLocation: Location {
        get { selectedRange.location }
        set { selectedRange = Buffer.Range(location: newValue, length: 0) }
    }

    @inlinable @inline(__always)
    public func select(_ range: Range) {
        selectedRange = range
    }

    @inlinable @inline(__always)
    public func insert(_ content: Content) throws {
        try replace(range: selectedRange, with: content)
    }

    @inlinable @inline(__always)
    public func character(at location: Location) throws -> Content {
        return try content(in: .init(location: location, length: 1))
    }
}
