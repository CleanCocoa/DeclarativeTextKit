import TextBuffer

public struct Modifying<Content> {
    public typealias ModificationBody = (AffectedRange) -> Content

    let range: AffectedRange
    let modification: ModificationBody
}

extension Modifying: Modification, Expression
where Content: Modification {
    @_disfavoredOverload
    public func evaluate(in buffer: any NSStringBuffer) -> Result<Content.Evaluation, BufferAccessFailure> {
        return _evaluate(in: buffer)
    }

    private func _evaluate<B: NSStringBuffer>(in buffer: B) -> Result<Content.Evaluation, BufferAccessFailure> {
        do {
            let scopedBuffer = try ScopedBufferSlice(base: buffer, scopedRange: range.value)

            return try scopedBuffer.modifyingScope {
                switch modification(range).evaluate(in: scopedBuffer) {
                case .success(var changeInLength):
                    range.consume(changeInLength: &changeInLength)
                    return .success(changeInLength)
                case .failure(let error):
                    return .failure(.wrap(error))
                }
            }
        } catch {
            return .failure(.wrap(error))
        }
    }

    public init(
        _ range: AffectedRange,
        @ModificationBuilder body: @escaping ModificationBody
    ) {
        self.range = range
        self.modification = body
    }
}
