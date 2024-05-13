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

    // MARK: Eagerly deciding where a newline goes in combinations

    public static func buildPartialBlock(
        accumulated: String,
        next: Line
    ) -> Line.EndsWithNewlineIfNeeded {
        return .init(accumulated + .newline + next.content)
    }

    public static func buildPartialBlock(
        accumulated: Line,
        next: String
    ) -> Line.StartsWithNewlineIfNeeded {
        return .init(accumulated.content + .newline + next)
    }
    
    public static func buildPartialBlock(
        accumulated: Line.EndsWithNewlineIfNeeded,
        next: String
    ) -> String {
        return .init(accumulated.content + .newline + next)
    }

    public static func buildPartialBlock(
        accumulated: Line.EndsWithNewlineIfNeeded,
        next: Line
    ) -> Line.EndsWithNewlineIfNeeded {
        return .init(accumulated.content + .newline + next.content)
    }

    public static func buildPartialBlock(
        accumulated: Line.StartsWithNewlineIfNeeded,
        next: String
    ) -> Line.StartsWithNewlineIfNeeded {
        return .init(accumulated.content + next)
    }

    public static func buildPartialBlock(
        accumulated: Line.StartsWithNewlineIfNeeded,
        next: Line
    ) -> Line {
        return .init(accumulated.content + .newline + next.content)
    }
}
