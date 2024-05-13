//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public protocol ExpressionEvaluation { }

public protocol Expression {
    associatedtype Evaluation: ExpressionEvaluation
    func evaluate(in buffer: Buffer) -> Evaluation
}
