//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

/// Command that does nothing.
public struct Noop: Expression {
    public typealias Evaluation = Void
    public typealias Failure = Never

    public init() { }
    public func evaluate(in buffer: Buffer) -> Result<Void, Never> { .success(()) }
}

extension Command {
    static let noop = Command(wrapped: Noop())
}
