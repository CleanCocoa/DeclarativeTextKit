import TextBuffer

public struct If: Modification, ChainableModification {
    let condition: () -> Bool
    let trueBranch: () -> ModificationSequence
    let falseBranch: () -> ModificationSequence

    public init(
        _ condition: @escaping @autoclosure () -> Bool,
        @ModificationBuilder _ trueBranch: @escaping () -> ModificationSequence
    ) {
        self.init(
            condition(),
            trueBranch,
            else: { Identity() }
        )
    }

    public init(
        _ condition: @escaping @autoclosure () -> Bool,
        @ModificationBuilder _ trueBranch: @escaping () -> ModificationSequence,
        @ModificationBuilder else falseBranch: @escaping () -> ModificationSequence
    ) {
        self.condition = condition
        self.trueBranch = trueBranch
        self.falseBranch = falseBranch
    }

    public func evaluate(in buffer: any NSStringBuffer) -> Result<ChangeInLength, BufferAccessFailure> {
        if condition() {
            return trueBranch().evaluate(in: buffer)
        } else {
            return falseBranch().evaluate(in: buffer)
        }
    }
}
