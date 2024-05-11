//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

extension Insert {
    public struct Runner {
        let textView: NSTextView

        public init(textView: NSTextView) {
            self.textView = textView
        }

        public func callAsFunction(_ command: Insert) {
            for insertion in command.insertions.reversed() {
                textView.apply(insertion)
            }
        }
    }
}

extension NSTextView {
    func apply(_ textInsertion: TextInsertion) {
        self.replaceCharacters(
            in: textInsertion.range,
            with: textInsertion.insertable.content
        )
    }
}
