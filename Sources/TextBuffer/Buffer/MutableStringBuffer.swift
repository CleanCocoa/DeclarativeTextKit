//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Foundation

/// Memory-efficient ``Buffer`` implementation (``MutableStringBuffer``) you can use for off-screen mutations and in unit tests.
public typealias InMemoryBuffer = MutableStringBuffer

/// A self-contained ``Buffer`` implementation, backed by `NSMutableString` as the UTF-16-offset indexed storage.
///
/// Used as in-memory buffers, you can apply changes to off-screen textual content in a way that is consistent with text views, but actually independent of these. Opposed to the platform's Text Kit views, which are large class clusters with a lot of automatic behavior pertaining layout, keeping a ``MutableStringBuffer`` in memory produces little overhead. (In fact, only as much overhead as a `NSMutableString` will, plus storing the selected range.)
///
/// To adapt other buffers and copy their content, use ``MutableStringBuffer/init(wrapping:)``.
///
/// ## Utility for Apps
///
/// - Use ``MutableStringBuffer`` in unit tests.
/// - Maintain multiple text buffers in memory while only ever rendering one buffer as a text view on screen, e.g. for opening multiple files in your app.
public final class MutableStringBuffer: Buffer {
    @usableFromInline
    let storage: NSMutableString

    @inlinable
    public var range: Buffer.Range { Buffer.Range(location: 0, length: self.storage.length) }

    @inlinable
    public var content: Content { self.storage as Buffer.Content }

    public var selectedRange: Buffer.Range

    fileprivate init(
        storage: NSMutableString,
        selectedRange: Buffer.Range
    ) {
        self.storage = storage
        self.selectedRange = selectedRange
    }

    /// Create a new `NSMutableString`-backed buffer based on `content`.
    ///
    /// > Invariant: The insertion point starts at the beginning of the buffer.
    public convenience init(_ content: Buffer.Content) {
        self.init(
            storage: NSMutableString(string: content),
            selectedRange: Buffer.Range(location: 0, length: 0)
        )
    }

    @inlinable
    public func lineRange(for searchRange: Buffer.Range) throws -> Buffer.Range {
        guard contains(range: searchRange) else {
            throw BufferAccessFailure.outOfRange(
                requested: searchRange,
                available: self.range
            )
        }
        return self.storage.lineRange(for: searchRange)
    }

    @inlinable
    public func content(in subrange: UTF16Range) throws -> Buffer.Content {
        guard contains(range: subrange) else {
            throw BufferAccessFailure.outOfRange(
                requested: subrange,
                available: self.range
            )
        }
        return self.storage.unsafeContent(in: subrange)
    }

    /// Raises an `NSExceptionName` of name `.rangeException` if `location` is out of bounds.
    @inlinable
    public func unsafeCharacter(at location: Buffer.Location) -> Buffer.Content {
        return self.storage.unsafeCharacter(at: location)
    }

    @inlinable
    public func insert(_ content: Content, at location: Location) throws {
        guard contains(range: .init(location: location, length: 0)) else {
            throw BufferAccessFailure.outOfRange(
                location: location,
                available: self.range
            )
        }

        self.storage.insert(content, at: location)

        self.selectedRange = self.selectedRange
            .shifted(by: location <= self.selectedRange.location ? length(of: content) : 0)  // Nudges selection to the right if needed.
    }

    @inlinable
    public func delete(in deletedRange: Buffer.Range) throws {
        guard contains(range: deletedRange) else {
            throw BufferAccessFailure.outOfRange(
                requested: deletedRange,
                available: self.range
            )
        }

        self.storage.deleteCharacters(in: deletedRange)
        self.selectedRange.subtract(deletedRange)
    }

    @inlinable
    public func replace(range replacementRange: Buffer.Range, with content: Buffer.Content) throws {
        guard contains(range: replacementRange) else {
            throw BufferAccessFailure.outOfRange(
                requested: replacementRange,
                available: self.range
            )
        }

        self.storage.replaceCharacters(in: replacementRange, with: content)

        self.selectedRange = self.selectedRange
            .subtracting(replacementRange)  // Removes potential overlap with the replacement range.
            .shifted(by: replacementRange.location <= self.selectedRange.location ? length(of: content) : 0)  // Nudges selection to the right if needed.
    }

    @inlinable
    public func modifying<T>(affectedRange: Buffer.Range, _ block: () -> T) throws -> T {
        guard contains(range: affectedRange) else {
            throw BufferAccessFailure.outOfRange(
                requested: affectedRange,
                available: self.range
            )
        }

        return block()
    }
}

extension MutableStringBuffer {
    /// Create a copy of `buffer`.
    public convenience init<Wrapped>(
        wrapping buffer: Wrapped
    ) where Wrapped: Buffer {
        self.init(
            storage: NSMutableString(string: buffer.content),
            selectedRange: buffer.selectedRange
        )
    }
}

extension MutableStringBuffer: Equatable {
    public static func == (lhs: MutableStringBuffer, rhs: MutableStringBuffer) -> Bool {
        return lhs.selectedRange == rhs.selectedRange
            && lhs.storage.isEqual(rhs.storage)
    }
}

extension MutableStringBuffer: CustomStringConvertible {
    /// A textual representation of this buffer that includes its selection in the output.
    ///
    /// - Selected ranges will be wrapped in guillemets (`«...»`, typed on US keyboard via <kbd>⌥|</kbd> and <kbd>⌥⇧|</kbd>), while
    /// - insertion point locations will show as `ˇ` (<kbd>⌥⇧t</kbd>).
    ///
    ///
    /// ```swift
    /// let buffer = MutableStringBuffer("Hello, world!")
    /// print(buffer) // => "ˇHello, world!"
    /// buffer.select(Buffer.Range(location: 7, length: 5))
    /// print(buffer) // => "Hello, «world»!"
    /// ```
    public var description: String {
        let result = NSMutableString(string: self.content)
        if self.isSelectingText {
            result.insert("»", at: self.selectedRange.endLocation)
            result.insert("«", at: self.selectedRange.location)
        } else {
            result.insert("ˇ", at: self.selectedRange.location)
        }
        return result as String
    }
}
