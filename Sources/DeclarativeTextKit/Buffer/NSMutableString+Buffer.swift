//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension NSMutableString: Buffer {
    public var range: Buffer.Range { Buffer.Range(location: 0, length: self.length) }

    /// Raises an `NSExceptionName` of name `.rangeException` if `location` is out of bounds.
    public func unsafeCharacter(at location: UTF16Offset) -> Buffer.Content {
        return self.substring(with: rangeOfComposedCharacterSequence(at: location))
    }

    public func select(_ range: Buffer.Range) {
        // no op
    }

    public var selectedRange: Buffer.Range {
        return .init(location: NSNotFound, length: 0)
    }
}
