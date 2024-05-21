//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension NSRange {
    /// - Returns: Whether `other` is fully contained in the receiver.
    @usableFromInline
    func contains(_ other: NSRange) -> Bool {
        return self.intersection(other) == other
    }
}
