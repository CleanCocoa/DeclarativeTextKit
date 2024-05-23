//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public struct Command {
    @usableFromInline
    let body: (any Buffer) -> Result<Void, Swift.Error>

    @usableFromInline
    init<Wrapped>(wrapped: Wrapped)
    where Wrapped: Expression {
        self.body = { buffer in
            return wrapped.evaluate(in: buffer)
                .map { _ in () }
                .mapError { $0 as Swift.Error }
        }
    }
}

extension Command: Expression {
    public typealias Evaluation = Void
    public typealias Failure = Swift.Error

    @_disfavoredOverload
    @inlinable
    public func evaluate(in buffer: Buffer) -> Result<Void, Swift.Error> {
        return body(buffer)
    }
}
