//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import TextBuffer

public protocol ModifiableBuffer: Buffer {
    /// Entry point into the Domain-Specific Language to run ``Expression``s on the buffer, acting on the whole range. This variant is suited to perform effects where you're not interested in the current selection.
    ///
    /// Conforming types can provide refinements to this process to bundle changes in e.g. undoable action groups.
    ///
    /// Builds `expression` and evaluates it on `self` so you can write a block directly like so:
    ///
    /// ```swift
    /// let range = ...
    /// buffer.evaluate { in
    ///     Select(WordRange(range))
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
        @ModificationBuilder _ expression: (_ fullRange: AffectedRange) throws -> ModificationSequence
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
    /// > Note: While _selecting_ a wider range than the input `range` is permitted, changes to the buffer contents outside of `range` are not allowed and will throw a ``/TextBuffer/BufferAccessFailure``.
    @inlinable @inline(__always)
    @discardableResult
    func evaluate(
        in range: Buffer.Range,
        @ModificationBuilder _ expression: (_ selectedRange: AffectedRange) throws -> ModificationSequence
    ) throws -> ChangeInLength
}
