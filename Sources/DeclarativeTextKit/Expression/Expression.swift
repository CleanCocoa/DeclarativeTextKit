//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public protocol Expression {
    associatedtype Evaluation
    associatedtype Failure: Error

    // We can't use `@_disfavoredOverload` here because then convincing the compiler to use this Result<V,E> overload becomes very tricky. Instead, annotate concrete implementations in conforming types as `@_disfavoredOverload`.
    func evaluate(in buffer: Buffer) -> Result<Evaluation, Failure>
}

extension Expression {
    @inlinable @inline(__always)
    public func evaluate(in buffer: Buffer) throws -> Evaluation {
        try self.evaluate(in: buffer).get()
    }
}

extension Expression where Failure == Never {
    @inlinable @inline(__always)
    public func evaluate(in buffer: Buffer) -> Evaluation {
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
