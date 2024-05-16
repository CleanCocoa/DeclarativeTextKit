//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension NSMutableString {
    @usableFromInline
    func unsafeCharacter(at location: Buffer.Location) -> Buffer.Content {
        return self.substring(with: self.rangeOfComposedCharacterSequence(at: location))
    }
}
