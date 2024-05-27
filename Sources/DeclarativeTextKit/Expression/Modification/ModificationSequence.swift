//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

/// Marks conforming types as being compatible with each other in a Result Builder sequence.
///
/// Since ``Insert`` and ``Delete`` are mutually exclusive in one block, this marker explicitly excludes these and allows compatible side-effects to be chained.
public protocol ChainableModification { }
extension Modifying: ChainableModification { }
extension Select: ChainableModification { }
extension Identity: ChainableModification { }

/// > Note: You don't create ``ModificationSequence``s manually, you use `@ModificationBuilder` blocks instead.
public struct ModificationSequence {
    // In the long term, we could support to chain any modification. At first, sorting out how to mix insertion and deletion isn't worth the trouble, though.
    public typealias Element = Modification & ChainableModification

    let commands: [any Element]

    init(_ commands: [any Element]) {
        self.commands = commands
    }
}

extension ModificationSequence: Modification {
    public func evaluate(in buffer: Buffer) -> Result<ChangeInLength, BufferAccessFailure> {
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
