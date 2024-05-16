//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import DeclarativeTextKit

func textView(_ string: String) -> NSTextView {
    let textView = NSTextView(usingTextLayoutManager: false)
    textView.string = string
    return textView
}
