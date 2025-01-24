//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation
import TextBuffer

public struct ChangeInLength: Equatable {
    public static var empty: ChangeInLength { .init(elements: []) }

    public typealias Delta = Buffer.Length

    @usableFromInline
    enum Element: Equatable {
        case unappliedToSelection(Delta)
        case appliedToSelection(Delta)

        var delta: Delta {
            return switch self {
            case .unappliedToSelection(let delta): delta
            case .appliedToSelection(let delta): delta
            }
        }
    }

    var elements: [Element]

    public var delta: Delta {
        return elements.map(\.delta).reduce(0, +)
    }

    @usableFromInline
    init(elements: [Element] = []) {
        self.elements = elements
    }

    public init(_ delta: Buffer.Length) {
        self.init(elements: [.unappliedToSelection(delta)])
    }
}

extension ChangeInLength {
    public static func + (lhs: ChangeInLength, rhs: ChangeInLength) -> ChangeInLength {
        return ChangeInLength(elements: lhs.elements + rhs.elements)
    }

    public static func += (lhs: inout ChangeInLength, rhs: ChangeInLength) {
        lhs = lhs + rhs
    }
}

extension ChangeInLength {
    public init(_ content: NSString) {
        self.init(content.length)
    }

    public init(_ content: String) {
        self.init((content as NSString).length)
    }
}
