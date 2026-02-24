import TextBuffer

public protocol ChainableModification { }
extension Modifying: ChainableModification { }
extension Select: ChainableModification { }
extension Identity: ChainableModification { }
extension ModificationSequence: ChainableModification { }

public struct ModificationSequence {
    internal static var empty: ModificationSequence { .init([]) }

    public typealias Element = Modification & ChainableModification

    let commands: [any Element]

    internal init(_ commands: [any Element]) {
        self.commands = commands
    }
}

extension ModificationSequence: Modification {
    public func evaluate(in buffer: any NSStringBuffer) -> Result<ChangeInLength, BufferAccessFailure> {
        do {
            var changeInLength: ChangeInLength = .empty
            for command in commands {
                changeInLength += try command.evaluate(in: buffer)
            }
            return .success(changeInLength)
        } catch {
            return .failure(.wrap(error))
        }
    }
}
