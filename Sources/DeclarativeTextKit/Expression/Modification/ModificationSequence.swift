//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import TextBuffer

/// Marks conforming types as being compatible with each other in a Result Builder sequence.
///
/// Since ``Insert`` and ``Delete`` are mutually exclusive in one block, this marker explicitly excludes these and allows compatible side-effects to be chained.
public protocol ChainableModification { }
extension Modifying: ChainableModification { }
extension Select: ChainableModification { }
extension Identity: ChainableModification { }
extension ModificationSequence: ChainableModification { }

/// > Note: You don't create ``ModificationSequence``s manually, you use `@ModificationBuilder` blocks instead.
public struct ModificationSequence {
    /// An empty modification sequence, obtainable via e.g. `if` with falsy condition, or empty `for` loops.
    ///
    /// Internal visibility, like `init`, so users don't add `ModificationSequence.empty` in their blocks.
    internal static var empty: ModificationSequence { .init([]) }

    // In the long term, we could support to chain any modification. At first, sorting out how to mix insertion and deletion isn't worth the trouble, though.
    public typealias Element = Modification & ChainableModification

    let commands: [any Element]

    internal init(_ commands: [any Element]) {
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
