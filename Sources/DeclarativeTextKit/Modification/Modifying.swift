//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

/// Marking a ``Buffer/Range`` as to-be-modified, combining Modifications into one block.
public struct Modifying<Content>: Command
where Content: Modification {
    let range: SelectedRange
    let modification: (Buffer.Range) -> Content

    public init(
        _ range: SelectedRange,
        @ModificationBuilder body: @escaping (Buffer.Range) -> Content
    ) {
        self.range = range
        self.modification = body
    }

    mutating public func callAsFunction(buffer: Buffer) {
        let changeInLength = modification(range.value).apply(to: buffer)
        range.value.length += changeInLength.delta
    }
}
