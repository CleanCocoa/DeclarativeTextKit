//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

/// Marking a ``Buffer/Range`` as to-be-modified, combining Modifications into one block.
public struct Modifying<Content>
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
}

extension Modifying: Expression {
    public typealias Evaluation = Void
    public typealias Failure = BufferAccessFailure

    @_disfavoredOverload  // Favor the throwing alternative of the protocol extension
    public func evaluate(in buffer: Buffer) -> Result<Void, BufferAccessFailure> {
        return _evaluate(in: buffer)
    }

    private func _evaluate<B: Buffer>(in buffer: B) -> Result<Void, BufferAccessFailure> {
        do {
            let scopedBuffer = try ScopedBufferSlice(base: buffer, scopedRange: range.value)

            return try scopedBuffer.modifyingScope { () -> Result<Void, BufferAccessFailure> in
                switch modification(range.value).evaluate(in: scopedBuffer) {
                case .success(let changeInLength):
                    range.value.length += changeInLength.delta
                    return .success(())
                case .failure(let failure):
                    return .failure(failure)
                }
            }
        } catch {
            return .failure(.wrap(error))
        }
    }
}

extension Modifying {
    public init(
        _ range: Buffer.Range,
        @ModificationBuilder body: @escaping (Buffer.Range) -> Content
    ) {
        self.init(SelectedRange(range), body: body)
    }

    public init(
        location: Buffer.Location,
        length: Buffer.Length,
        @ModificationBuilder body: @escaping (Buffer.Range) -> Content
    ) {
        self.init(Buffer.Range(location: location, length: length), body: body)
    }
}
