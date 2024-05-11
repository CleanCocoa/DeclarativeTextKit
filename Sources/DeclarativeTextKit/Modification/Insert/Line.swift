//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

/// Ensures its ``content`` is enclosed by newline characters left and right upon insertion.
public struct Line: Insertable {
    public let content: Buffer.Content

    public init(_ content: Buffer.Content) {
        self.content = content
    }

    public func insert(in buffer: Buffer, at location: UTF16Offset) {
        let newlineBefore = location > buffer.range.lowerBound
            ? buffer.newline(at: location - 1)
            : true  // Favor not adding a newline at the start of a file
        let newlineAfter = location < buffer.range.upperBound
            ? buffer.newline(at: location)
            : false  // Favor ending with newline at EOF

        if !newlineAfter {
            buffer.insert(.newline, at: location)
        }

        content.insert(in: buffer, at: location)

        if !newlineBefore {
            buffer.insert(.newline, at: location)
        }
    }
}

// MARK: Half-Open Line

extension Line {
    /// Ensures its ``content`` is prepended by newline characters (left).
    public struct PrefixNewlineIfNeeded: Insertable {
        public let content: Buffer.Content

        @usableFromInline
        internal init(_ content: Buffer.Content) {
            self.content = content
        }

        @inlinable
        public func insert(in buffer: Buffer, at location: UTF16Offset) {
            let newlineBefore = location > buffer.range.lowerBound
                ? buffer.newline(at: location - 1)
                : true  // Favor not adding a newline at the start of a file

            content.insert(in: buffer, at: location)

            if !newlineBefore {
                buffer.insert(.newline, at: location)
            }
        }
    }

    /// Ensures its ``content`` is appended by a newline characters (right).
    public struct PostfixNewlineIfNeeded: Insertable {
        public let content: Buffer.Content

        @usableFromInline
        internal init(_ content: Buffer.Content) {
            self.content = content
        }

        @inlinable
        public func insert(in buffer: Buffer, at location: UTF16Offset) {
            let newlineAfter = location < buffer.range.upperBound
                ? buffer.newline(at: location)
                : false  // Favor ending with newline at EOF

            if !newlineAfter {
                buffer.insert(.newline, at: location)
            }

            content.insert(in: buffer, at: location)
        }
    }
}

extension String {
    @usableFromInline
    static var newline: String { "\n" }
}

extension Buffer {
    @usableFromInline
    func newline(at location: UTF16Offset) -> Bool {
        return character(at: location) == .newline
    }
}
