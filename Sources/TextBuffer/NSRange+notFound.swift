//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

extension NSRange {
    @inlinable
    public static var notFound: NSRange { NSRange(location: NSNotFound, length: 0) }
}
