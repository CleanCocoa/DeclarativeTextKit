import TextBuffer

public protocol Insertable {
    func insert(
        in buffer: any NSStringBuffer,
        at location: Int
    ) throws -> ChangeInLength
}

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
