//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import TextBuffer

/// Branching paths where optional unwrapping happens lazily during evaluation time.
///
/// Since we don't have `if let` support from the Result Builder, ``IfLet`` is added for consistency to express unwrapping in the DSL.
///
/// ## Motivation for an ``IfLet`` type in spite of Swift Result Builder's capabilities
///
/// If you think of ``Buffer/evaluate(_:)-7jmtt`` as the "run time", Swift Result Builder's `buildOptional` and `buildEither` check their condition at "compile time". That means you cannot form conditions on ``AffectedRange``.
///
/// This is a confusing limitation, and brings with it potentially dangerous (as in: crashing) situations.
///
/// > Further Reading: For a detailed explanation of the "runtime" and "build time" concepts, or to learn more about how to think about Swift Result Builders, see <doc:Runtime>.
///
/// ## Example
///
/// Appends an optional string to the buffer if it's non-nil.
///
/// ```swift
/// var optionalValue: String? = ...
/// try buffer.evaluate { fullRange in
///     IfLet (optionalValue) { value in
///         Modifying(fullRange) {
///             Insert($0.endLocation) { value }
///         }
///     }
/// }
/// ```
public struct IfLet<Wrapped>: Modification, ChainableModification {
    let binding: () -> Optional<Wrapped>
    let trueBranch: (Wrapped) -> ModificationSequence
    let falseBranch: () -> ModificationSequence

    /// Branching path without an `else` clause.
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

    /// Branching path with an `else` clause.
    public init(
        _ condition: @escaping @autoclosure () -> Optional<Wrapped>,
        @ModificationBuilder _ trueBranch: @escaping (Wrapped) -> ModificationSequence,
        @ModificationBuilder else falseBranch: @escaping () -> ModificationSequence
    ) {
        self.binding = condition
        self.trueBranch = trueBranch
        self.falseBranch = falseBranch
    }

    public func evaluate(in buffer: any Buffer) -> Result<ChangeInLength, BufferAccessFailure> {
        if let value = binding() {
            return trueBranch(value).evaluate(in: buffer)
        } else {
            return falseBranch().evaluate(in: buffer)
        }
    }
}
