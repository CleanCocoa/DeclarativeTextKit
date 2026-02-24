import TextBuffer

public struct Debug: Modification, ChainableModification {
    let block: () -> Void

    public init(_ block: @escaping () -> Void) {
        self.block = block
    }

    public func evaluate(in buffer: any NSStringBuffer) -> Result<ChangeInLength, BufferAccessFailure> {
        block()
        return .success(.empty)
    }
}
