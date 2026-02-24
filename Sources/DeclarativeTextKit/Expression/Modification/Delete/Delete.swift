import Foundation
import TextBuffer

public struct Delete {
    let deletions: () -> SortedArray<TextDeletion>

    init(
        _ deletions: @escaping @autoclosure () -> SortedArray<TextDeletion>
    ) {
        self.deletions = deletions
    }
}

extension Delete {
    init(
        _ deletion: @escaping @autoclosure () -> TextDeletion
    ) {
        self.init(SortedArray(sorted: [deletion()]))
    }

    public init(
        location: @escaping @autoclosure () -> Int,
        length: @escaping @autoclosure () -> Int
    ) {
        self.init(
            TextDeletion(
                range: NSRange(
                    location: location(),
                    length: length()
                )
            )
        )
    }

    public init(
        _ range: @escaping @autoclosure () -> NSRange
    ) {
        self.init(TextDeletion(range: range()))
    }

    public init(
        _ selectedRange: @escaping @autoclosure () -> AffectedRange
    ) {
        self.init(selectedRange().value)
    }

    public init(
        _ rangeExpression: @escaping @autoclosure () -> Range<Int>
    ) {
        self.init(TextDeletion(rangeExpression()))
    }
}


struct TextDeletion: Comparable {
    static func < (lhs: TextDeletion, rhs: TextDeletion) -> Bool {
        return lhs.range.location < rhs.range.location
    }

    let range: NSRange

    init(range: NSRange) {
        self.range = range
    }
}

extension TextDeletion {
    init(_ rangeExpression: Range<Int>) {
        self.init(range: NSRange(
            location: rangeExpression.lowerBound,
            length: rangeExpression.count
        ))
    }
}
