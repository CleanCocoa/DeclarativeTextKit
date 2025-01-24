//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import TextBuffer

/// Executes its block during command evaluation time.
///
/// ## Example
///
/// The following will print to the console how `someRange` is being adjusted during the ``Modifying`` block.
///
/// ```swift
/// Debug { print("Range before:", someRange)  // => "Range before: {100,50}"
/// Modifying(someRange) {
///     Delete(location: someRange.location, length: someRange.length / 2)
/// }
/// Debug { print("Range after:", someRange)  // => "Range after: {100,25}"
/// ```
public struct Debug: Modification, ChainableModification {
    let block: () -> Void

    public init(_ block: @escaping () -> Void) {
        self.block = block
    }

    public func evaluate(in buffer: any Buffer) -> Result<ChangeInLength, BufferAccessFailure> {
        block()
        return .success(.empty)
    }
}
