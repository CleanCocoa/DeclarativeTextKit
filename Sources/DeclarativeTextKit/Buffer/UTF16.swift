//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

public typealias UTF16Range = NSRange
public typealias UTF16Offset = Int
public typealias UTF16Length = Int

extension UTF16Range {
    @inlinable
    public var endLocation: UTF16Offset { upperBound }
}

public func length(of string: NSString) -> UTF16Length {
    return string.length
}

@_disfavoredOverload
public func length(of string: String) -> UTF16Length {
    return length(of: string as NSString)
}
