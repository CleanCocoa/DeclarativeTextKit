//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public struct Insert {
    let insertions: SortedArray<TextInsertion>

    init(_ insertions: SortedArray<TextInsertion>) {
        self.insertions = insertions
    }

    public init(
        _ location: UTF16Offset,
        @InsertableBuilder _ body: () -> Insertable
    ) {
        self.init(SortedArray(sorted: [
            TextInsertion(at: location, insertable: body())
        ], areInIncreasingOrder: TextInsertion.arePositionedInIncreasingOrder))
    }
}


struct TextInsertion {
    static func arePositionedInIncreasingOrder (lhs: TextInsertion, rhs: TextInsertion) -> Bool {
        return lhs.range.location < rhs.range.location
    }

    let range: UTF16Range
    let insertable: Insertable

    init(range: UTF16Range, insertable: Insertable) {
        self.range = range
        self.insertable = insertable
    }

    init(at location: UTF16Offset, insertable: Insertable) {
        self.init(
            range: UTF16Range(location: location, length: 0),
            insertable: insertable
        )
    }
}
