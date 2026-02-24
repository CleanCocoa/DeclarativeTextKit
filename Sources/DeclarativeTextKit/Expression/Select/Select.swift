import Foundation
import TextBuffer

public struct Select<RangeExpr>
where RangeExpr: BufferRangeExpression {
    let range: () -> RangeExpr
    let body: (_ selectedRange: AffectedRange) -> ModificationSequence
}

// MARK: - Selection DSL

extension Select {
    public init(
        _ range: @escaping @autoclosure () -> RangeExpr,
        @ModificationBuilder _ body: @escaping (_ selectedRange: AffectedRange) -> ModificationSequence
    ) {
        self.range = range
        self.body = body
    }

    public init(
        _ range: @escaping @autoclosure () -> RangeExpr
    ) {
        self.init(range()) { _ in Identity() }
    }
}

extension Select where RangeExpr == NSRange {
    public init(
        _ range: @escaping @autoclosure () -> NSRange
    ) {
        self.init(range()) { _ in Identity() }
    }

    public init(
        _ location: @escaping @autoclosure () -> Int
    ) {
        self.init(NSRange(location: location(), length: 0)) { _ in Identity() }
    }

    public init(
        location: @escaping @autoclosure () -> Int,
        length: @escaping @autoclosure () -> Int,
        @ModificationBuilder _ body: @escaping (_ selectedRange: AffectedRange) -> ModificationSequence
    ) {
        self.init(
            NSRange(location: location(), length: length()),
            body
        )
    }

    public init(
        location: @escaping @autoclosure () -> Int,
        length: @escaping @autoclosure () -> Int
    ) {
        self.init(
            location: location(),
            length: length()
        ) { _ in Identity() }
    }
}

// MARK: - Acting as executable Command

extension Select: Modification {
    @_disfavoredOverload
    public func evaluate(in buffer: any NSStringBuffer) -> Result<ChangeInLength, BufferAccessFailure> {
        do {
            let selectedRange = AffectedRange(try range().evaluate(in: buffer).bufferRange())

            try buffer.select(selectedRange)

            let commandInSelectionContext = body(selectedRange)
            return commandInSelectionContext.evaluate(in: buffer)
        } catch {
            return .failure(.wrap(error))
        }
    }
}
