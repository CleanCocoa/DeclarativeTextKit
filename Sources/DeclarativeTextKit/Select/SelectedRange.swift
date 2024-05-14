//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

/// A ``Buffer/Range`` value that can be modified over the course of multiple ``Modification``s like a reference type.
public struct SelectedRange {
    private final class Box {
        var value: Buffer.Range

        init(_ value: Buffer.Range) {
            self.value = value
        }
    }

    private let boxedValue: Box

    public private(set) var value: Buffer.Range {
        get { boxedValue.value }
        set { boxedValue.value = newValue }
    }

    public var location: Buffer.Location { value.location }
    public var endLocation: Buffer.Location { value.endLocation }
    public var length: Buffer.Length { value.length }

    public init(_ range: Buffer.Range) {
        self.boxedValue = Box(range)
    }
}

extension SelectedRange {
    public init(
        location: Buffer.Location,
        length: Buffer.Length
    ) {
        self.init(Buffer.Range(location: location, length: length))
    }
}

extension SelectedRange: Equatable {
    public static func == (lhs: SelectedRange, rhs: SelectedRange) -> Bool {
        lhs.value == rhs.value
    }
}
