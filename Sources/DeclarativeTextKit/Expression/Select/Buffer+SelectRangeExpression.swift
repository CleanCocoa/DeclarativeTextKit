//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import TextBuffer

extension Buffer {
    public func select<RangeExpr>(_ rangeExpression: RangeExpr) throws
    where RangeExpr: BufferRangeExpression {
        self.select(try rangeExpression.evaluate(in: self).bufferRange())
    }
}
