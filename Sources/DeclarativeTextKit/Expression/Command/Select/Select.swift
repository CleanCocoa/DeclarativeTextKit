//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public struct Select<RangeExpr>
where RangeExpr: BufferRangeExpression {
    let range: RangeExpr
    let body: (_ selectedRange: SelectedRange) -> CommandSequence
}

// MARK: - Selection DSL

extension Select {
    public init(
        _ range: RangeExpr,
        @CommandSequenceBuilder _ body: @escaping (_ selectedRange: SelectedRange) -> CommandSequence
    ) {
        self.range = range
        self.body = body
    }

    public init(_ range: RangeExpr) {
        self.init(range) { _ in Command.noop }
    }
}

extension Select where RangeExpr == Buffer.Range {
    public init(_ range: Buffer.Range) {
        self.init(range) { _ in Command.noop }
    }

    public init(_ location: Buffer.Location) {
        self.init(Buffer.Range(location: location, length: 0)) { _ in Command.noop }
    }

    public init(
        location: Buffer.Location,
        length: Buffer.Length,
        @CommandSequenceBuilder _ body: @escaping (_ selectedRange: SelectedRange) -> CommandSequence
    ) {
        self.init(
            Buffer.Range(location: location, length: length),
            body
        )
    }
}

// MARK: - Acting as executable Command

extension Select: Expression {
    public typealias Evaluation = Void
    public typealias Failure = CommandSequenceFailure

    @_disfavoredOverload  // Favor the throwing alternative of the protocol extension
    public func evaluate(in buffer: Buffer) -> Result<Void, CommandSequenceFailure> {
        let selectedRange = SelectedRange(range.evaluate(in: buffer).bufferRange())

        buffer.select(selectedRange)

        let commandInSelectionContext = body(selectedRange)
        return commandInSelectionContext.evaluate(in: buffer)
    }
}
