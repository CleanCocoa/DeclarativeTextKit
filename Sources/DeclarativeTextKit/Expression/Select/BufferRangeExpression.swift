//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public protocol BufferRangeEvaluation {
    func bufferRange() throws -> Buffer.Range
}

public protocol BufferRangeExpression: Expression 
where Evaluation: BufferRangeEvaluation, Failure == Never {
    func evaluate(in buffer: Buffer) -> Evaluation
}

extension BufferRangeExpression {
    public func evaluate(in buffer: Buffer) -> Result<Evaluation, Never> {
        return .success(evaluate(in: buffer) as Evaluation)
    }
}
