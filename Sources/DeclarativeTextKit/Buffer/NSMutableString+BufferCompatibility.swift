//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension NSMutableString {
    @usableFromInline
    func unsafeCharacter(at location: Buffer.Location) -> Buffer.Content {
        return unsafeContent(in: .init(location: location, length: 1))
    }

    @usableFromInline
    func unsafeContent(in range: Buffer.Range) -> Buffer.Content {
        return self.substring(with: self.rangeOfComposedCharacterSequences(for: range))
    }
}
