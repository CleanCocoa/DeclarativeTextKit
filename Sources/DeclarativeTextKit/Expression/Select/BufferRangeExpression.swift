import Foundation
import TextBuffer

public protocol BufferRangeEvaluation {
    func bufferRange() throws -> NSRange
}

public protocol BufferRangeExpression: Expression
where Evaluation: BufferRangeEvaluation, Failure == Never {
    func evaluate(in buffer: any NSStringBuffer) -> Evaluation
}

extension BufferRangeExpression {
    public func evaluate(in buffer: any NSStringBuffer) -> Result<Evaluation, Never> {
        return .success(evaluate(in: buffer) as Evaluation)
    }
}
