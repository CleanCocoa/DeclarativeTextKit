
//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

/// Marking a ``Buffer/Range`` as to-be-modified in a range.
public struct Modifying<Content> {
    public typealias ModificationBody = (Buffer.Range) -> Content

    let range: SelectedRange
    let modification: ModificationBody
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

            return try scopedBuffer.modifyingScope {
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
        @ModificationBuilder body: @escaping ModificationBody
    ) {
        self.range = range
        self.modification = body
    }

    public init(
        _ range: Buffer.Range,
        @ModificationBuilder body: @escaping ModificationBody
    ) {
        self.init(SelectedRange(range), body: body)
    }

    public init(
        location: Buffer.Location,
        length: Buffer.Length,
        @ModificationBuilder body: @escaping ModificationBody
    ) {
        self.init(Buffer.Range(location: location, length: length), body: body)
    }
}
