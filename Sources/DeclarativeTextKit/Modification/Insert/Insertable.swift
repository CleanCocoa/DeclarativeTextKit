//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public protocol Insertable {
    func insert(in buffer: Buffer, at location: Buffer.Location)
}

@resultBuilder
public struct InsertableBuilder {
    public static func buildPartialBlock<I>(first: I) -> I
    where I: Insertable {
        return first
    }

    // MARK: Reducing consecutive Lines

    public static func buildPartialBlock(
        accumulated: Line,
        next: Line
    ) -> Line {
        return Line(accumulated.content + .newline + next.content)
    }

    // MARK: Reducing consecutive Strings

    public static func buildPartialBlock(
        accumulated: String,
        next: String
    ) -> String {
        return accumulated + next
    }

    // MARK: Half-Opening Lines

    /// While ``Line`` is a lazy decision to wrap its content in newlines left and right, concatenation to a string eagerly decides that the left-hand newline will be needed.
    public static func buildPartialBlock(
        accumulated: String,
        next: Line
    ) -> Line.PostfixNewlineIfNeeded {
        return .init(accumulated + .newline + next.content)
    }

    /// While ``Line`` is a lazy decision to wrap its content in newlines left and right, concatenting a string to a ``Line`` eagerly decides that the right-hand newline will be needed.
    public static func buildPartialBlock(
        accumulated: Line,
        next: String
    ) -> Line.PrefixNewlineIfNeeded {
        return .init(accumulated.content + .newline + next)
    }
    
    /// While ``Line/PostfixNewlineIfNeeded`` is a lazy decision to append a newline, concatenting a string to it decides that the right-hand newline will be needed. The result is a simple string.
    public static func buildPartialBlock(
        accumulated: Line.PostfixNewlineIfNeeded,
        next: String
    ) -> String {
        return .init(accumulated.content + .newline + next)
    }

    public static func buildPartialBlock(
        accumulated: Line.PostfixNewlineIfNeeded,
        next: Line
    ) -> Line.PostfixNewlineIfNeeded {
        return .init(accumulated.content + .newline + next.content)
    }

    /// Concatenating a string to a half-open line that ensures a newline will be needed to its left-hand-side can expand the half-open line itself.
    public static func buildPartialBlock(
        accumulated: Line.PrefixNewlineIfNeeded,
        next: String
    ) -> Line.PrefixNewlineIfNeeded {
        return .init(accumulated.content + next)
    }

    public static func buildPartialBlock(
        accumulated: Line.PrefixNewlineIfNeeded,
        next: Line
    ) -> Line {
        return .init(accumulated.content + .newline + next.content)
    }
}
