import TextBuffer

extension Insert: Modification {
    @_disfavoredOverload
    public func evaluate(in buffer: any NSStringBuffer) -> Result<ChangeInLength, BufferAccessFailure> {
        return Result {
            try self.insertions()
                .reversed()
                .reduce(into: ChangeInLength.empty) { changeInLength, insertion in
                    changeInLength += try insertion.insert(in: buffer)
                }
        }.mapError(BufferAccessFailure.wrap(_:))
    }
}

extension TextInsertion {
    fileprivate func insert(in buffer: any NSStringBuffer) throws -> ChangeInLength {
        return try insertable.insert(in: buffer, at: location)
    }
}
