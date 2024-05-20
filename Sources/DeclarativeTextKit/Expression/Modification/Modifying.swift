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

    @_disfavoredOverload  // Favor the throwing alternative of the protocol extension
    public func evaluate(in buffer: Buffer) -> Result<Void, ModificationFailure> {
        switch modification(range.value).evaluate(in: buffer) {
        case .success(let changeInLength):
            range.value.length += changeInLength.delta
            return .success(())
        case .failure(let failure):
            return .failure(failure)
        }
    }
}
