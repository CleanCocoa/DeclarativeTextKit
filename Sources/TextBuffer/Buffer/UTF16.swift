//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

public typealias UTF16Range = NSRange
public typealias UTF16Offset = Int
public typealias UTF16Length = Int

extension UTF16Range {
    /// > Warning: Produces a runtime exception if you try to set `endLocation` to a value lower than `location`, which would produce a negative `length`.
    @inlinable
    public var endLocation: UTF16Offset {
        get { upperBound }
        set {
            precondition(location <= newValue)
            length = newValue - location
        }
    }

    /// > Warning: Produces a runtime exception if you try to set `endLocation` to a value lower than `startLocation`, which would produce a negative `length`.
    @inlinable @inline(__always)
    public init(
        startLocation: UTF16Offset,
        endLocation: UTF16Offset
    ) {
        precondition(startLocation <= endLocation)
        self.init(location: startLocation, length: endLocation - startLocation)
    }
}

@inlinable @inline(__always)
public func length(of string: NSString) -> UTF16Length {
    return string.length
}

@inlinable @inline(__always)
@_disfavoredOverload
public func length(of string: String) -> UTF16Length {
    return length(of: string as NSString)
}
