//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

/// Changes the ``Buffer/selectedRange`` on the user's behalf when evaluated. Takes into account changes to buffer length and selection offsets from mutations in the same block, if any.
///
/// When performed after mutations like ``Insert`` and ``Delete``, the range represented by ``SelectedRange`` will reflect any changes appropiately by the time ``Select`` is evaluated.
///
/// This means you can work with ranges to express your intent, instead of having to do offset calculations yourself:
///
/// ```swift
/// // Given a rather large range inside a buffer:
/// let someRange = Buffer.Range(
///     location: 100,
///     length: 200
/// )
/// Modifying(someRange) { affectedRange in
///     // Deletion a large chunk that will reduce the length
///     // by -190 characters.
///     Modifying(affectedRange) {
///         Delete(
///             location: affectedRange.location + 10,
///             length: affectedRange.length - 10
///         )
///     }
///
///     // At this time, `endLocation` correctly reflects
///     // the new length (=100+10=110).
///     Select(affectedRange.endLocation)
/// }
/// ```
///
/// Opposed to manual offset calculations, you don't need to take the deletion into account to calculate the "after the end" location to let the user type there. This ensures that you can alter buffer mutations to best express the change you need, adding and removing characters, while keeping the ``Select`` command untouched.
public struct Select<RangeExpr>
where RangeExpr: BufferRangeExpression {
    let range: RangeExpr
    let body: (_ selectedRange: SelectedRange) -> ModificationSequence
}

// MARK: - Selection DSL

extension Select {
    public init(
        _ range: RangeExpr,
        @ModificationBuilder _ body: @escaping (_ selectedRange: SelectedRange) -> ModificationSequence
    ) {
        self.range = range
        self.body = body
    }

    public init(_ range: RangeExpr) {
        self.init(range) { _ in Identity() }
    }
}

extension Select where RangeExpr == Buffer.Range {
    public init(_ range: Buffer.Range) {
        self.init(range) { _ in Identity() }
    }

    public init(_ location: Buffer.Location) {
        self.init(Buffer.Range(location: location, length: 0)) { _ in Identity() }
    }

    public init(
        location: Buffer.Location,
        length: Buffer.Length,
        @ModificationBuilder _ body: @escaping (_ selectedRange: SelectedRange) -> ModificationSequence
    ) {
        self.init(
            Buffer.Range(location: location, length: length),
            body
        )
    }

    public init(
        location: Buffer.Location,
        length: Buffer.Length
    ) {
        self.init(
            location: location,
            length: length
        ) { _ in Identity() }
    }
}

// MARK: - Acting as executable Command

extension Select: Modification {
    @_disfavoredOverload  // Favor the throwing alternative of the protocol extension
    public func evaluate(in buffer: Buffer) -> Result<ChangeInLength, BufferAccessFailure> {
        let selectedRange = SelectedRange(range.evaluate(in: buffer).bufferRange())

        buffer.select(selectedRange)

        let commandInSelectionContext = body(selectedRange)
        return commandInSelectionContext.evaluate(in: buffer)
    }
}
