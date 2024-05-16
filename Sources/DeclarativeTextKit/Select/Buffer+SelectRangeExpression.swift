//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

extension Buffer {
    public func select<RangeExpr>(_ rangeExpression: RangeExpr)
    where RangeExpr: BufferRangeExpression {
        self.select(rangeExpression.evaluate(in: self).bufferRange())
    }
}
