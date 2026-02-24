import TextBuffer

public struct Identity: Modification {
    public init() { }
    public func evaluate(in buffer: any NSStringBuffer) -> Result<ChangeInLength, BufferAccessFailure> {
        return .success(.empty)
    }
}
