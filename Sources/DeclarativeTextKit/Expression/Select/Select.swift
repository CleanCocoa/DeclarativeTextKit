//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

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
