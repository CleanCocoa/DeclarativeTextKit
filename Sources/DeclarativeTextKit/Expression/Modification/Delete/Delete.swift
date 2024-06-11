//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

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
        location: @escaping @autoclosure () -> Buffer.Location,
        length: @escaping @autoclosure () -> Buffer.Length
    ) {
        self.init(
            TextDeletion(
                range: Buffer.Range(
                    location: location(),
                    length: length()
                )
            )
        )
    }

    public init(
        _ range: @escaping @autoclosure () -> Buffer.Range
    ) {
        self.init(TextDeletion(range: range()))
    }

    public init(
        // 2024-06-11: I believe that it's not necessary to make access to this reference type-like value 'lazy' with an autoclosure -- access to `value` will be wrapped in an autoclosure already, but I can't yet prove that this is the case.
        _ selectedRange: @escaping @autoclosure () -> AffectedRange
    ) {
        self.init(selectedRange().value)
    }

    public init(
        _ rangeExpression: @escaping @autoclosure () -> Range<Buffer.Location>
    ) {
        self.init(TextDeletion(rangeExpression()))
    }
}


struct TextDeletion: Comparable {
    static func < (lhs: TextDeletion, rhs: TextDeletion) -> Bool {
        return lhs.range.location < rhs.range.location
    }

    let range: Buffer.Range

    init(range: Buffer.Range) {
        self.range = range
    }
}

extension TextDeletion {
    init(_ rangeExpression: Range<Buffer.Location>) {
        self.init(range: Buffer.Range(
            location: rangeExpression.lowerBound,
            length: rangeExpression.count
        ))
    }
}
