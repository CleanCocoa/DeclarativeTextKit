//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import TextBuffer

/// Branching paths where the condition is checked lazily during evaluation time.
///
/// ## Motivation for an ``If`` type in spite of Swift Result Builder's capabilities
///
/// If you think of ``Buffer/evaluate(_:)-7jmtt`` as the "run time", Swift Result Builder's `buildOptional` and `buildEither` check their condition at "compile time". That means you cannot form conditions on ``AffectedRange``.
///
/// This is a confusing limitation, and brings with it potentially dangerous (as in: crashing) situations.
///
/// > Further Reading: For a detailed explanation of the "runtime" and "build time" concepts, or to learn more about how to think about Swift Result Builders, see <doc:Runtime>.
///
/// ## Example
///
/// Wrap the current selection or adjacent word in parentheses. If the selection is empty, put the insertion point between the two parentheses: `(ˇ)`. This information can only be known at evaluation time, so ``If`` is a good fit:
///
/// ```swift
/// try buffer.evaluate {
///     Select(WordRange(buffer.selectedRange)) { selectedWordRange in
///         Modifying(selectedWordRange) {
///             Insert($0.location) { Word.Prepending("(") }
///             Insert($0.endLocation) { Word.Appending(")") }
///         }
///         If (selectedWordRange.length == 2) {
///             Select(selectedWordRange.location + 1)
///         }
///     }
/// }
/// ```
public struct If: Modification, ChainableModification {
    let condition: () -> Bool
    let trueBranch: () -> ModificationSequence
    let falseBranch: () -> ModificationSequence

    /// Branching path without an `else` clause.
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

    /// Branching path with an `else` clause.
    public init(
        _ condition: @escaping @autoclosure () -> Bool,
        @ModificationBuilder _ trueBranch: @escaping () -> ModificationSequence,
        @ModificationBuilder else falseBranch: @escaping () -> ModificationSequence
    ) {
        self.condition = condition
        self.trueBranch = trueBranch
        self.falseBranch = falseBranch
    }

    public func evaluate(in buffer: any Buffer) -> Result<ChangeInLength, BufferAccessFailure> {
        if condition() {
            return trueBranch().evaluate(in: buffer)
        } else {
            return falseBranch().evaluate(in: buffer)
        }
    }
}
