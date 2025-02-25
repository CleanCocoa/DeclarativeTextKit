//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import TextBuffer

/// Modification that does nothing.
public struct Identity: Modification {
    public init() { }
    public func evaluate(in buffer: any Buffer) -> Result<ChangeInLength, BufferAccessFailure> {
        return .success(.empty)
    }
}
