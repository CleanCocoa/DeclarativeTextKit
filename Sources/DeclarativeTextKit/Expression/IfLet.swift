import TextBuffer

public struct IfLet<Wrapped>: Modification, ChainableModification {
    let binding: () -> Optional<Wrapped>
    let trueBranch: (Wrapped) -> ModificationSequence
    let falseBranch: () -> ModificationSequence

    public init(
        _ condition: @escaping @autoclosure () -> Optional<Wrapped>,
        @ModificationBuilder _ trueBranch: @escaping (Wrapped) -> ModificationSequence
    ) {
        self.init(
            condition(),
            trueBranch,
            else: { Identity() }
        )
    }

    public init(
        _ condition: @escaping @autoclosure () -> Optional<Wrapped>,
        @ModificationBuilder _ trueBranch: @escaping (Wrapped) -> ModificationSequence,
        @ModificationBuilder else falseBranch: @escaping () -> ModificationSequence
    ) {
        self.binding = condition
        self.trueBranch = trueBranch
        self.falseBranch = falseBranch
    }

    public func evaluate(in buffer: any NSStringBuffer) -> Result<ChangeInLength, BufferAccessFailure> {
        if let value = binding() {
            return trueBranch(value).evaluate(in: buffer)
        } else {
            return falseBranch().evaluate(in: buffer)
        }
    }
}
