//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

/// A text buffer contains UTF16 characters.
public protocol Buffer: AnyObject {
    typealias Location = UTF16Offset
    typealias Length = UTF16Length
    typealias Range = UTF16Range
    typealias Content = String

    var range: Range { get }

    var content: Content { get }
    func unsafeCharacter(at location: Location) -> Content

    var selectedRange: Range { get }

    /// Whether the buffer would insert text at an insertion point additively, or whether it is in selection mode and insertion would overwrite text.
    var isSelectingText: Bool { get }

    func select(_ range: Range)
    func lineRange(for range: Range) -> Range

    /// Inserts `content` at `location`, not affecting the typing location of ``selectedRange`` in the process.
    func insert(_ content: Content, at location: Location)

    /// Inserts `content` at the current typing location of ``selectedRange``.
    ///
    /// This replaces any existing selected text. The ``selectedRange`` is modified in the process:
    ///
    /// - inserting text at the insertion point moves the insertion point by `length(of: content)`,
    /// - replacing text moves the insertion point to the end of the inserted text (exiting the selection mode).
    func insert(_ content: Content)

    func delete(in range: Range)

    func replace(range: Range, with content: Content)
}

import Foundation // For inlining isSelectingText as long as Buffer.Range is a typealias

extension Buffer {
    @inlinable @inline(__always)
    public var isSelectingText: Bool { selectedRange.length > 0 }

    @inlinable @inline(__always)
    public func insert(_ content: Content) {
        replace(range: selectedRange, with: content)
    }
}
