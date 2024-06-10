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

    public static func buildArray(_ components: [Insert]) -> Insert {
        return Insert(SortedArray(
            unsorted: components.map(\.insertions).joined(),
            areInIncreasingOrder: TextInsertion.arePositionedInIncreasingOrder
        ))
    }
}

// MARK: - Building sequences of Deletions

extension ModificationBuilder {
    public static func buildPartialBlock(first: Delete) -> Delete {
        return first
    }

    public static func buildPartialBlock(accumulated: Delete, next: Delete) -> Delete {
        return Delete(SortedArray(
            unsorted: Array(accumulated.deletions) + Array(next.deletions)
        ))
    }

    public static func buildArray(_ components: [Delete]) -> Delete {
        return Delete(SortedArray(
            unsorted: components.map(\.deletions).joined()
        ))
    }
}

// MARK: - Building sequences of utility commands

extension ModificationBuilder {
    public static func buildPartialBlock(
        first: some ModificationSequence.Element
    ) -> ModificationSequence {
        return ModificationSequence([first])
    }

    public static func buildPartialBlock(
        accumulated: ModificationSequence,
        next: some ModificationSequence.Element
    ) -> ModificationSequence {
        return ModificationSequence(
            accumulated.commands + [next]
        )
    }

    public static func buildOptional(_ component: ModificationSequence?) -> ModificationSequence {
        if let component {
            return component
        } else {
            return .empty
        }
    }

    public static func buildEither(first component: ModificationSequence) -> ModificationSequence {
        return component
    }

    public static func buildEither(second component: ModificationSequence) -> ModificationSequence {
        return component
    }
}
