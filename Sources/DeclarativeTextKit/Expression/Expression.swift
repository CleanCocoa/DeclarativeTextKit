//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public protocol Expression {
    associatedtype Evaluation
    associatedtype Failure: Error

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
        try! self.evaluate(in: buffer).get()
    }
}

extension Expression where Evaluation == Void {
    @inlinable @inline(__always)
    public func evaluate(in buffer: Buffer) throws {
        return try self.evaluate(in: buffer).get()
    }
}
