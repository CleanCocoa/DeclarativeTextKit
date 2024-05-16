//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

@resultBuilder
public struct ModificationBuilder { }

// MARK: - Building sequences of Insertions

extension ModificationBuilder {
    public static func buildPartialBlock(first: Insert) -> Insert {
        return first
    }

    public static func buildPartialBlock(accumulated: Insert, next: Insert) -> Insert {
        return Insert(SortedArray(
            unsorted: Array(accumulated.insertions) + Array(next.insertions),
            areInIncreasingOrder: TextInsertion.arePositionedInIncreasingOrder
        ))
    }
}

extension ModificationBuilder {
    public static func buildPartialBlock(first: Delete) -> Delete {
        return first
    }

    public static func buildPartialBlock(accumulated: Delete, next: Delete) -> Delete {
        return Delete(SortedArray(
            unsorted: Array(accumulated.deletions) + Array(next.deletions)
        ))
    }
}
