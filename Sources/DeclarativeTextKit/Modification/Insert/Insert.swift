//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public struct Insert: Modification {
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
        return lhs.location < rhs.location
    }

    let location: UTF16Offset
    let insertable: Insertable

    init(at location: UTF16Offset, insertable: Insertable) {
        self.location = location
        self.insertable = insertable
    }
}
