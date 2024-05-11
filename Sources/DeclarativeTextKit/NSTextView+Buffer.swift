//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

extension NSTextView: Buffer {
    public var range: Buffer.Range { Buffer.Range(location: 0, length: self.nsMutableString.length) }

    /// Raises an `NSExceptionName` of name `.rangeException` if `location` is out of bounds.
    public func character(at location: UTF16Offset) -> String {
        return self.nsMutableString
            .substring(with: NSRange(location: location, length: 1))
    }

    public func insert(_ content: Content, at location: Location) {
        self.nsMutableString.insert(content, at: location)
    }
}
