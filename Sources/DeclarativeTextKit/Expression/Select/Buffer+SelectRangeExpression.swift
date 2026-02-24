import TextBuffer

extension NSStringBuffer {
    public func select<RangeExpr>(_ rangeExpression: RangeExpr) throws
    where RangeExpr: BufferRangeExpression {
        self.select(try rangeExpression.evaluate(in: self).bufferRange())
    }
}
