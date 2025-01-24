//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import TextBuffer

// We can't make the base `Buffer` protocol conform to `ModifiableBuffer`, so we extend all base buffers instead.

extension NSTextViewBuffer: ModifiableBuffer { }
extension MutableStringBuffer: ModifiableBuffer { }
