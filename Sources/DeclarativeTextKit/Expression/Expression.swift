import TextBuffer

public protocol Expression {
    associatedtype Evaluation
    associatedtype Failure: Error

    func evaluate(in buffer: any NSStringBuffer) -> Result<Evaluation, Failure>
}

extension Expression {
    @inlinable @inline(__always)
    public func evaluate(in buffer: any NSStringBuffer) throws -> Evaluation {
        try self.evaluate(in: buffer).get()
    }
}

extension Expression where Failure == Never {
    @inlinable @inline(__always)
    public func evaluate(in buffer: any NSStringBuffer) -> Evaluation {
        return self.evaluate(in: buffer).get()
    }
}

extension Swift.Result where Failure == Never {
    @usableFromInline
    func get() -> Success {
        switch self {
        case .success(let value): return value
        }
    }
}
