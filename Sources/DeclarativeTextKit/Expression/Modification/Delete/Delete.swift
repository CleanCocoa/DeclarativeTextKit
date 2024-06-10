//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public struct Delete {
    let deletions: SortedArray<TextDeletion>

    init(_ deletions: SortedArray<TextDeletion>) {
        self.deletions = deletions
    }
}

extension Delete {
    init(_ deletion: TextDeletion) {
        self.init(SortedArray(sorted: [deletion]))
    }

    public init(location: Buffer.Location, length: Buffer.Length) {
        self.init(TextDeletion(range: Buffer.Range(location: location, length: length)))
    }

    public init(_ range: Buffer.Range) {
        self.init(TextDeletion(range: range))
    }

    public init(_ selectedRange: AffectedRange) {
        self.init(selectedRange.value)
    }

    public init(_ rangeExpression: Range<Buffer.Location>) {
        self.init(TextDeletion(rangeExpression))
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
