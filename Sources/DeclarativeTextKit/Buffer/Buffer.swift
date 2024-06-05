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

    /// Expanded `range` to conver whole lines. Chained calls returns the same line range, i.e. does not expand line by line.
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
    func lineRange(for range: Range) -> Range

    /// Expanded `baseRange` to conver whole words. Chained calls returns the same line range, i.e. does not expand line by line.
    /// - Throws: ``BufferAccessFailure`` if `subrange` exceeds ``range``.
    func wordRange(for range: Range) throws -> Range

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

    /// Entry point into the Domain-Specific Language to run ``Expression``s on the buffer.
    ///
    /// Conforming types can provide refinements to this process to bundle changes in e.g. undoable action groups.
    ///
    /// Builds `expression` and evaluates it on `self` so you can write a block directly like so:
    ///
    /// ```swift
    /// buffer.evaluate {
    ///     Modifying(buffer.selectedRange) { range in
    ///         Insert(range.location) { "> " }
    ///     }
    /// }
    /// ```
    ///
    /// An alternative way would be to separate the command from its evaluation in a procedural style:
    ///
    /// ```swift
    /// let command = Modifying(buffer.selectedRange) { range in
    ///     Insert(range.location) { "> " }
    /// }
    /// let changeInLength = try command.evaluate(in: buffer)
    /// ```
    @discardableResult
    func evaluate(
        @ModificationBuilder _ expression: () throws -> ModificationSequence
    ) throws -> ChangeInLength
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

    @inlinable @inline(__always)
    public func contains(range: Buffer.Range) -> Bool {
        // Appending at the trailing end of the buffer is technically outside of its range, but permitted.
        if range.length == 0 {
            return self.range.isValidInsertionPointLocation(at: range.location)
        }
        // Overwriting rules are the same as deletion rules.
        return self.range.contains(range)
    }

    @inlinable @inline(__always)
    @discardableResult
    public func evaluate(
        @ModificationBuilder _ expression: () throws -> ModificationSequence
    ) throws -> ChangeInLength {
        return try expression().evaluate(in: self)
    }
}

// MARK: - Word Range

@usableFromInline
let wordBoundary: CharacterSet = .whitespacesAndNewlines
    .union(.punctuationCharacters)
    .union(.symbols)
    .union(.illegalCharacters)  // Not tested

extension Buffer {
    @inlinable
    public func wordRange(
        for baseRange: Buffer.Range
    ) throws -> Buffer.Range {

        guard self.contains(range: baseRange)
        else { throw BufferAccessFailure.outOfRange(requested: baseRange, available: self.range) }

        // This bridging overhead isn't ideal while we operate on `Swift.String` as the `Buffer.Content`. It makes NSRange-based string enumeration easier. As long as `wordRange(for:)` is used to apply commands on the user's behalf via DeclarativeTextKit, we should be okay in practice even for longer document. Repeated calls to this function, e.g. in loops, could be a disaster, though. See commit d434030e6d9366941c5cc3fa9c6de860afb74710 for an approach that uses two while loops instead.
        let nsContent = (self.content as NSString)

        var start = self.range.location
        nsContent.enumerateSubstrings(
            in: Buffer.Range(
                location: self.range.location,
                length: baseRange.location
            ),
            options: [.byComposedCharacterSequences, .reverse]
        ) { characterSequence, characterSequenceRange, enclosingRange, stop in
            guard let characterSequence = characterSequence as? NSString
            else { assertionFailure(); return }
            if characterSequence.rangeOfCharacter(from: wordBoundary) == NSRange(location: 0, length: characterSequence.length) {
                start = characterSequenceRange.endLocation
                stop.pointee = true
            }
        }

        var end = self.range.endLocation
        nsContent.enumerateSubstrings(
            in: Buffer.Range(
                location: baseRange.endLocation,
                length: self.range.length - baseRange.endLocation
            ),
            options: [.byComposedCharacterSequences]
        ) { characterSequence, characterSequenceRange, enclosingRange, stop in
            guard let characterSequence = characterSequence as? NSString
            else { assertionFailure(); return }
            if characterSequence.rangeOfCharacter(from: wordBoundary) == NSRange(location: 0, length: characterSequence.length) {
                end = characterSequenceRange.location
                stop.pointee = true
            }
        }

        return Buffer.Range(
            location: start,
            length: end - start
        )
    }
}
