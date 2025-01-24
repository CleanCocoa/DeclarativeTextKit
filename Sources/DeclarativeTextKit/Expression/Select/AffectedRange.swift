//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation
import TextBuffer

/// A ``/TextBuffer/Buffer/Range`` value that can be modified over the course of multiple ``Modification``s. Behaves like a reference type under the hood.
///
/// For example, the following will print to the console how a ``AffectedRange`` is being adjusted during the ``Modifying`` block to reflect that the length changed during deletion:
///
/// ```swift
/// Debug { print("Range before:", someRange)  // => "Range before: {100,50}"
/// Modifying(someRange) {
///     Delete(location: someRange.location, length: someRange.length / 2)
/// }
/// Debug { print("Range after:", someRange)  // => "Range after: {100,25}"
/// ```
public struct AffectedRange {
    private final class Box {
        var value: Buffer.Range

        init(_ value: Buffer.Range) {
            self.value = value
        }
    }

    private let boxedValue: Box

    public internal(set) var value: Buffer.Range {
        get { boxedValue.value }
        nonmutating set { boxedValue.value = newValue }
    }

    public var location: Buffer.Location { value.location }
    public var endLocation: Buffer.Location { value.endLocation }
    public var length: Buffer.Length {
        get { value.length }
        nonmutating set { value.length = newValue }
    }

    public init(_ range: Buffer.Range) {
        self.boxedValue = Box(range)
    }
}

extension AffectedRange {
    public init(
        location: Buffer.Location,
        length: Buffer.Length
    ) {
        self.init(Buffer.Range(location: location, length: length))
    }
}

extension AffectedRange: CustomStringConvertible {
    public var description: String {
        "(\(value.location)..<\(value.endLocation))(len=\(value.length))"
    }
}
