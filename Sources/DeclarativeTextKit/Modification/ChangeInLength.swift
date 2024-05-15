//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

public struct ChangeInLength: Equatable {
    public let delta: Buffer.Length

    public init(_ delta: Buffer.Length = 0) {
        self.delta = delta
    }
}

extension ChangeInLength {
    public static func + (lhs: ChangeInLength, rhs: ChangeInLength) -> ChangeInLength {
        return ChangeInLength(lhs.delta + rhs.delta)
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
