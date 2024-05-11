//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit

extension Insert {
    public struct Runner {
        let textView: NSTextView

        public init(textView: NSTextView) {
            self.textView = textView
        }

        public func callAsFunction(_ command: Insert) {
            command.insertions.reversed()
                .forEach { $0.insert(in: textView) }
        }
    }
}

extension TextInsertion {
    func insert(in buffer: Buffer) {
        insertable.insert(in: buffer, at: location)
    }
}
