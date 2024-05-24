
//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

/// Marking a ``Buffer/Range`` as to-be-modified in a range.
public struct Modifying<Content> {
    let range: SelectedRange
    let modification: (Buffer.Range) -> Content
}

extension Modifying: Expression
where Content: Expression {
    @_disfavoredOverload  // For client code, favor the throwing alternative available from the protocol extension.
    public func evaluate(in buffer: Buffer) -> Result<Content.Evaluation, BufferAccessFailure> {
        return _evaluate(in: buffer)
    }

    private func _evaluate<B: Buffer>(in buffer: B) -> Result<Content.Evaluation, BufferAccessFailure> {
        do {
            let scopedBuffer = try ScopedBufferSlice(base: buffer, scopedRange: range.value)

            return try scopedBuffer.modifyingScope { () -> Result<Content.Evaluation, BufferAccessFailure> in
                switch modification(range.value).evaluate(in: scopedBuffer) {
                case .success(let value):
                    if let changeInLength = value as? ChangeInLength {
                        range.value.length += changeInLength.delta
                    }
                    return .success(value)
                case .failure(let error):
                    return .failure(.wrap(error))
                }
            }
        } catch {
            return .failure(.wrap(error))
        }
    }
}

// MARK: - Grouping content `Modification`s

extension Modifying: Modification
where Content: Modification {
    public init(
        _ range: SelectedRange,
        @ModificationBuilder body: @escaping (Buffer.Range) -> Content
    ) {
        self.range = range
        self.modification = body
    }

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

// MARK: - Grouping side-effects as `CommandSequence`

extension Modifying
where Content == CommandSequence {
    @_disfavoredOverload  // Given two block-based initializers, favor the `Content: Modification` initializer.
    public init(
        _ range: SelectedRange,
        @CommandSequenceBuilder body: @escaping (Buffer.Range) -> CommandSequence
    ) {
        self.range = range
        self.modification = body
    }

    @_disfavoredOverload  // Given two block-based initializers, favor the `Content: Modification` initializer.
    public init(
        _ range: Buffer.Range,
        @CommandSequenceBuilder body: @escaping (Buffer.Range) -> CommandSequence
    ) {
        self.init(SelectedRange(range), body: body)
    }

    @_disfavoredOverload  // Given two block-based initializers, favor the `Content: Modification` initializer.
    public init(
        location: Buffer.Location,
        length: Buffer.Length,
        @CommandSequenceBuilder body: @escaping (Buffer.Range) -> CommandSequence
    ) {
        self.init(Buffer.Range(location: location, length: length), body: body)
    }
}
