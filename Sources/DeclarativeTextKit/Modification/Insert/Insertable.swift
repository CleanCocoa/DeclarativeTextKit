//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public protocol Insertable {
    var content: String { get }
}

@resultBuilder
public struct InsertableBuilder {
    public static func buildPartialBlock(first: Insertable) -> Insertable {
        return first
    }

    public static func buildPartialBlock(accumulated: some Insertable, next: some Insertable) -> some Insertable {
        return Concat(left: accumulated, right: next)
    }
}

/// Content string concatenation of the contents of `Left` and `Right`, lazily evaluated.
///
/// Used in ``Insert/init(_:_:)`` to represent text insertion of multiple pieces at 1 location.
struct Concat<Left, Right>: Insertable
where Left: Insertable, Right: Insertable {
    let left: Left
    let right: Right
    var content: String { left.content + right.content }
}
