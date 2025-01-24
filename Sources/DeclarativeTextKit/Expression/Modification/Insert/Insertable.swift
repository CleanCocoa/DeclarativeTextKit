//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import TextBuffer

/// Inserts itself into a ``/TextBuffer/Buffer`` at time of evaluation.
public protocol Insertable {
    func insert(
        in buffer: Buffer,
        at location: Buffer.Location
    ) throws -> ChangeInLength
}

/// Result Builder used in ``Insert/init(_:_:)`` to allow insertion of complex strings that can guarantee invariants, like ``Line`` ensures the inserted text is wrapped in newline characters (`"\n"`) in the resulting buffer, depending on existing content in that place.
@resultBuilder
public struct InsertableBuilder {
    @inlinable
    public static func buildPartialBlock<I>(first: I) -> I
    where I: Insertable {
        return first
    }

    // MARK: Reducing consecutive Words

    @inlinable
    public static func buildPartialBlock(
        accumulated: Word,
        next: Word
    ) -> Word {
        return Word(accumulated.content + Word.space + next.content)
    }

    // MARK: Reducing consecutive Lines

    @inlinable
    public static func buildPartialBlock(
        accumulated: Line,
        next: Line
    ) -> Line {
        return Line(accumulated.content + Line.break + next.content)
    }

    // MARK: Reducing consecutive Strings

    @inlinable
    public static func buildPartialBlock(
        accumulated: String,
        next: String
    ) -> String {
        return accumulated + next
    }

    // MARK: Eagerly deciding where a newline goes in combinations

    @inlinable
    public static func buildPartialBlock(
        accumulated: String,
        next: Line
    ) -> Line.EndsWithNewlineIfNeeded {
        return .init(accumulated + Line.break + next.content)
    }

    @inlinable
    public static func buildPartialBlock(
        accumulated: Line,
        next: String
    ) -> Line.StartsWithNewlineIfNeeded {
        return .init(accumulated.content + Line.break + next)
    }

    @inlinable
    public static func buildPartialBlock(
        accumulated: Line.EndsWithNewlineIfNeeded,
        next: String
    ) -> String {
        return .init(accumulated.content + Line.break + next)
    }

    @inlinable
    public static func buildPartialBlock(
        accumulated: Line.EndsWithNewlineIfNeeded,
        next: Line
    ) -> Line.EndsWithNewlineIfNeeded {
        return .init(accumulated.content + Line.break + next.content)
    }

    @inlinable
    public static func buildPartialBlock(
        accumulated: Line.StartsWithNewlineIfNeeded,
        next: String
    ) -> Line.StartsWithNewlineIfNeeded {
        return .init(accumulated.content + next)
    }

    @inlinable
    public static func buildPartialBlock(
        accumulated: Line.StartsWithNewlineIfNeeded,
        next: Line
    ) -> Line {
        return .init(accumulated.content + Line.break + next.content)
    }
}
