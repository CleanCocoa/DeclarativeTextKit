//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

public protocol Expression {
    associatedtype Evaluation
    func evaluate(in buffer: Buffer) -> Evaluation
}

extension Expression where Evaluation == Void {
    @inlinable @inline(__always)
    public func callAsFunction(buffer: Buffer) {
        self.evaluate(in: buffer)
    }
}
