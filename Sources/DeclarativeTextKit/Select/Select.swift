//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public struct Select<Range>: Command
where Range: BufferRangeExpression {
    let range: Range
    let body: (_ selectedRange: SelectedRange) -> CommandSequence
}

// MARK: - DSL

extension Select {
    public init(
        _ range: Range,
        @CommandSequenceBuilder _ body: @escaping (_ selectedRange: SelectedRange) -> CommandSequence
    ) {
        self.range = range
        self.body = body
    }

    public init(_ range: Range) {
        self.init(range) { _ in Noop() }
    }
}

extension Select where Range == Buffer.Range {
    public init(_ range: Buffer.Range) {
        self.init(range) { _ in Noop() }
    }

    public init(_ location: Buffer.Location) {
        self.init(Buffer.Range(location: location, length: 0)) { _ in Noop() }
    }
}

// MARK: -

extension Select: Expression {
    public struct Selection: ExpressionEvaluation {
        public let buffer: Buffer
        public let selectedRange: Buffer.Range

        init(buffer: Buffer, selectedRange: Buffer.Range) {
            self.buffer = buffer
            self.selectedRange = selectedRange
        }

        public func callAsFunction() {
            buffer.select(selectedRange)
        }
    }

    public func evaluate(in buffer: Buffer) -> Selection {
        return Selection(
            buffer: buffer,
            selectedRange: range.evaluate(in: buffer).bufferRange()
        )
    }
}
