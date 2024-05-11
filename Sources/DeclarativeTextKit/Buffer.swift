//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

/// A text buffer contains characters.
public protocol Buffer {
    typealias Location = UTF16Offset
    typealias Length = UTF16Length
    typealias Range = UTF16Range
    typealias Content = String

    var range: Range { get }

    func character(at location: Location) -> Content
    func insert(_ content: Content, at location: Location)
}
