//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

/// A text buffer contains UTF16 characters.
public protocol Buffer: AnyObject {
    typealias Location = UTF16Offset
    typealias Length = UTF16Length
    typealias Range = UTF16Range
    typealias Content = String

    var range: Range { get }

    var content: Content { get }

    func select(_ range: Range)
    var selectedRange: Range { get }

    func lineRange(for range: Range) -> Range

    func unsafeCharacter(at location: Location) -> Content
    func insert(_ content: Content, at location: Location)
}
