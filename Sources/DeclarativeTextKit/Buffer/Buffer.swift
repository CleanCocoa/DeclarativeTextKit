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

    /// Entry point into the Domain-Specific Language to run ``Expression``s on the buffer.
    ///
    /// Conforming types can provide refinements to this process to bundle changes in e.g. undoable action groups.
    ///
    /// Builds `expression` and evaluates it on `self` so you can write a block directly like so:
    ///
    /// ```swift
    /// buffer.evaluate(in: buffer.selectedRange) { selectedRange in
    ///     Modifying(selectedRange) { range in
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

    /// Entry point into the Domain-Specific Language to run ``Expression``s on the buffer, acting on the whole range.
    ///
    /// Conforming types can provide refinements to this process to bundle changes in e.g. undoable action groups.
    ///
    /// Builds `expression` and evaluates it on `self` so you can write a block to e.g. append a text to the buffer like this:
    ///
    /// ```swift
    /// buffer.evaluate { fullRange in
    ///     Modifying(fullRange) { wrappedRange in
    ///         Insert(wrappedRange.endLocation) { "!" }
    ///     }
    /// }
    /// ```
    @discardableResult
    @_disfavoredOverload
    func evaluate(
        @ModificationBuilder _ expression: (AffectedRange) throws -> ModificationSequence
    ) throws -> ChangeInLength

    /// Entry point into the Domain-Specific Language to run ``Expression``s on the buffer within `range`.
    ///
    /// Conforming types can provide refinements to this process to bundle changes in e.g. undoable action groups.
    ///
    /// Builds `expression` and evaluates it on `self` so you can write a block directly like so:
    ///
    /// ```swift
    /// buffer.evaluate(in: buffer.selectedRange) { selectedRange in
    ///     Modifying(selectedRange) { wrappedRange in
    ///         Insert(wrappedRange.location) { "> " }
    ///     }
    /// }
    /// ```
    ///
    /// > Note: While _selecting_ a wider range than the input `range` is permitted, changes to the buffer contents outside of `range` are not allowed and will throw a ``BufferAccessFailure``.
    @inlinable @inline(__always)
    @discardableResult
    func evaluate(
        in range: Buffer.Range,
        @ModificationBuilder _ expression: (AffectedRange) throws -> ModificationSequence
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
        // Selection rules for replacing or deleting text require regular full containment.
        return self.range.contains(range)
    }
}

// MARK: - Evaluation helper / entry points

extension Buffer {
    @inlinable @inline(__always)
    @discardableResult
    public func evaluate(
        @ModificationBuilder _ expression: () throws -> ModificationSequence
    ) throws -> ChangeInLength {
        return try expression().evaluate(in: self)
    }

    @inlinable @inline(__always)
    @discardableResult
    public func evaluate(
        in range: Buffer.Range,
        @ModificationBuilder _ expression: (AffectedRange) throws -> ModificationSequence
    ) throws -> ChangeInLength {
        return try ScopedBufferSlice(
            base: self,
            scopedRange: range
        ).evaluate(in: range, expression)
    }

    @inlinable @inline(__always)
    @discardableResult
    @_disfavoredOverload
    public func evaluate(
        @ModificationBuilder _ expression: (AffectedRange) throws -> ModificationSequence
    ) throws -> ChangeInLength {
        return try self.evaluate(in: self.range, expression)
    }
}

// MARK: - Word Range

@usableFromInline
let wordBoundary: CharacterSet = .whitespacesAndNewlines
    .union(.punctuationCharacters)
    .union(.symbols)
    .union(.illegalCharacters)  // Not tested

extension NSRange {
    @inlinable
    func expanded(
        to other: NSRange,
        direction: Direction
    ) -> NSRange {
        precondition(other.location <= self.location && other.endLocation >= self.endLocation, "Expansion requires other range to be larger")

        let startLocation = switch direction {
        case .upstream: other.location
        case .downstream: self.location
        }

        let endLocation = switch direction {
        case .upstream: self.endLocation
        case .downstream: other.endLocation
        }

        return NSRange(
            startLocation: startLocation,
            endLocation: endLocation
        )
    }

    /// - Returns: Subrange that ends before `other`.
    @inlinable
    func prefix(upTo other: NSRange) -> NSRange {
        precondition(self.location <= other.location && self.endLocation >= other.location, "Prefix requires range to reach up to or encompass other range")

        return NSRange(
            startLocation: self.location,
            endLocation: other.location
        )
    }

    /// - Returns: Subrange that starts after `other`.
    @inlinable
    func suffix(after other: NSRange) -> NSRange {
        precondition(self.location <= other.endLocation && self.endLocation >= other.endLocation, "Suffix requires range to start right after or encompass other range")

        return NSRange(
            startLocation: other.endLocation,
            endLocation: self.endLocation
        )
    }
}

extension CharacterSet {
    @usableFromInline
    static let nonWhitespaceOrNewlines: CharacterSet = .whitespacesAndNewlines.inverted
}

extension CharacterSet {
    @inlinable
    func contains(characterSequence: NSString) -> Bool {
        return characterSequence.rangeOfCharacter(from: self) == NSRange(location: 0, length: characterSequence.length)
    }
}

extension Buffer {
    @inlinable
    public func wordRange(
        for baseRange: Buffer.Range
    ) throws -> Buffer.Range {

        guard self.contains(range: baseRange)
        else { throw BufferAccessFailure.outOfRange(requested: baseRange, available: self.range) }

        // This bridging overhead isn't ideal while we operate on `Swift.String` as the `Buffer.Content`. It makes NSRange-based string enumeration easier. As long as `wordRange(for:)` is used to apply commands on the user's behalf via DeclarativeTextKit, we should be okay in practice even for longer document. Repeated calls to this function, e.g. in loops, could be a disaster, though. See commit d434030e6d9366941c5cc3fa9c6de860afb74710 for an approach that uses two while loops instead.
        let nsContent = (self.content as NSString)

        func expanding(
            range searchRange: NSRange,
            upToCharactersFrom characterSet: CharacterSet
        ) -> Buffer.Range {
            var expandedRange = searchRange
            expandedRange = expanding(range: expandedRange, upToCharactersFrom: characterSet, direction: .upstream)
            expandedRange = expanding(range: expandedRange, upToCharactersFrom: characterSet, direction: .downstream)
            return expandedRange
        }

        func expanding(
            range searchRange: NSRange,
            upToCharactersFrom characterSet: CharacterSet,
            direction: Direction
        ) -> Buffer.Range {
            switch direction {
            case .upstream:
                let matchedLocation = locationOfCharacter(
                    in: characterSet,
                    startingAt: searchRange.location,
                    direction: .upstream)
                return Buffer.Range(
                    startLocation: matchedLocation ?? self.range.location, // If nothing was found, expand to start of the available range.
                    endLocation: searchRange.endLocation
                )
            case .downstream:
                let matchedLocation = locationOfCharacter(
                    in: characterSet,
                    startingAt: searchRange.endLocation,
                    direction: .downstream)
                return Buffer.Range(
                    startLocation: searchRange.location,
                    endLocation: matchedLocation ?? self.range.endLocation // If nothing was found, expand to end of the available range.
                )
            }
        }

        func locationOfCharacter(
            in characterSet: CharacterSet,
            startingAt startLocation: Buffer.Location,
            direction: Direction
        ) -> Buffer.Location? {
            let availableRange = self.range

            var nextLocation: Buffer.Location? = {
                let nextLocation = switch direction {
                case .upstream: startLocation - 1 // It's fine to not subtract a composed character sequence's length here since we'll fetch that in the loop.
                case .downstream: startLocation
                }
                guard availableRange.contains(nextLocation) else { return nil }
                return nextLocation
            }()

            func advanced(location: Buffer.Location) -> Buffer.Location? {
                switch direction {
                case .upstream:
                    guard location > availableRange.location else { return nil }
                    return nsContent.rangeOfComposedCharacterSequence(at: location - 1).location
                case .downstream:
                    guard location < availableRange.endLocation - 1 else { return nil }
                    return nsContent.rangeOfComposedCharacterSequence(at: location).endLocation
                }
            }

            while let location = nextLocation,
                  availableRange.contains(location) {
                let characterSequenceRange = nsContent.rangeOfComposedCharacterSequence(at: location)
                let characterSequence = nsContent.substring(with: characterSequenceRange) as NSString

                if characterSet.contains(characterSequence: characterSequence) {
                    return switch direction {
                    case .upstream: characterSequenceRange.endLocation
                    case .downstream: characterSequenceRange.location
                    }
                }

                nextLocation = advanced(location: location)
            }

            return nil
        }

        var searchRange = baseRange

        // Trim trailing whitespace first, favoring upstream selection affinity, e.g. if `baseRange` is all whitespace.
        if let newEndLocation = nsContent.locationUpToCharacter(
            from: .nonWhitespaceOrNewlines,
            direction: .upstream,
            in: searchRange.expanded(to: self.range, direction: .upstream))
        {
            searchRange = Buffer.Range(
                startLocation: searchRange.location,
                endLocation: max(newEndLocation, searchRange.location)  // If newEndLocation < location, the whole of searchRange is whitespace.
            )
        }
        // Trim leading whitespace
        if let newStartLocation = nsContent.locationUpToCharacter(
            from: .nonWhitespaceOrNewlines,
            direction: .downstream,
            in: searchRange.expanded(to: self.range, direction: .downstream)
           ) 
        {
            searchRange = Buffer.Range(
                startLocation: min(newStartLocation, searchRange.endLocation),  // If newStartLocation > endLocation, the whole searchRange is whitespace.
                endLocation: searchRange.endLocation
            )
        }

        var resultRange = expanding(range: searchRange, upToCharactersFrom: wordBoundary)

        // If the result is an empty range, characters adjacent to the location were all `wordBoundary` characters. Then we need to try again with relaxed conditions, skipping over whitespace first. Try forward search, then backward.
        if resultRange.length == 0 {
            let downstreamNonWhitespaceLocation = locationOfCharacter(in: .nonWhitespaceOrNewlines, startingAt: resultRange.location, direction: .downstream)
            let upstreamNonWhitespaceLocation = locationOfCharacter(in: .nonWhitespaceOrNewlines, startingAt: resultRange.endLocation, direction: .upstream)
            // Prioritize look-behind over look-ahead *only* of the point is left-adjacent to non-whitespace character and the look-ahead is further away.
            if let upstreamNonWhitespaceLocation,
               let downstreamNonWhitespaceLocation,
               (upstreamNonWhitespaceLocation ..< resultRange.location).count == 0,
               (resultRange.location ..< downstreamNonWhitespaceLocation).count > 0 {
                resultRange = expanding(range: .init(location: upstreamNonWhitespaceLocation, length: 0), upToCharactersFrom: .whitespacesAndNewlines)
            } else if let location = downstreamNonWhitespaceLocation ?? upstreamNonWhitespaceLocation {
                resultRange = expanding(range: .init(location: location, length: 0), upToCharactersFrom: .whitespacesAndNewlines)
            }
        }

        // When the input range covered only whitespace and nothing was found, discard the resulting empty range in favor of the original.
        if resultRange.length == 0, resultRange != baseRange {
            return baseRange
        }

        return resultRange
    }
}
