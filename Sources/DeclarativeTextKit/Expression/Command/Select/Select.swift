//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public struct Select<Range>
where Range: BufferRangeExpression {
    let range: Range
    let body: (_ selectedRange: SelectedRange) -> CommandSequence
}

// MARK: - Selection DSL

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

// MARK: - Acting as executable Command

extension Select: Command {
    public struct Selection {
        public let buffer: Buffer
        public let selectedRange: Buffer.Range

        init(buffer: Buffer, selectedRange: Buffer.Range) {
            self.buffer = buffer
            self.selectedRange = selectedRange
        }
    }

    public func evaluate(in buffer: Buffer) {
        let selection = Selection(
            buffer: buffer,
            selectedRange: range.evaluate(in: buffer).bufferRange()
        )

        buffer.select(selection)

        let commandInSelectionContext = body(SelectedRange(selection))
        commandInSelectionContext(buffer: buffer)
    }
}

extension Buffer {
    fileprivate func select<Range>(_ selection: Select<Range>.Selection)
    where Range: BufferRangeExpression {
        self.select(selection.selectedRange)
    }
}

extension SelectedRange {
    fileprivate init<Range>(_ selection: Select<Range>.Selection)
    where Range: BufferRangeExpression {
        self.init(selection.selectedRange)
    }
}
