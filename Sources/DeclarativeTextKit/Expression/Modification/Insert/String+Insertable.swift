import TextBuffer

extension Swift.String: Insertable {
    @inlinable
    public var content: String { self }

    public func insert(
        in buffer: any NSStringBuffer,
        at location: Int
    ) throws -> ChangeInLength {
        try buffer.insert(self, at: location)
        return ChangeInLength(self)
    }
}
