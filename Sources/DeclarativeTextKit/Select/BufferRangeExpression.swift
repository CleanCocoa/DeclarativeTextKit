//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public protocol BufferRangeEvaluation {
    func bufferRange() -> Buffer.Range
}

public protocol BufferRangeExpression: Expression 
where Evaluation: BufferRangeEvaluation {

}
