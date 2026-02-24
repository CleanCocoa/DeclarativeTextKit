import Foundation
import TextBuffer

@usableFromInline
final class ScopedBufferSlice<Base>: Buffer
where Base: Buffer {
    static func appending(to base: Base) throws -> ScopedBufferSlice<Base> {
        return try self.init(
            base: base,
            scopedRange: .init(location: base.range.location + base.range.length, length: 0)
        )
    }

    private let base: Base

    @usableFromInline var content: Base.Content { base.content }
    @usableFromInline var range: Base.Range { scopedRange }
    @usableFromInline var selectedRange: Base.Range {
        get { base.selectedRange }
        set { base.selectedRange = newValue }
    }

    private(set) var scopedRange: Base.Range

    @usableFromInline
    init(
        base: Base,
        scopedRange: Base.Range
    ) throws {
        guard base.contains(range: scopedRange) else {
            throw BufferAccessFailure.outOfRange(
                requested: scopedRange,
                available: base.range
            )
        }
        self.base = base
        self.scopedRange = scopedRange
    }

    @usableFromInline
    func content(in subrange: Base.Range) throws(BufferAccessFailure) -> Base.Content {
        guard contains(range: subrange) else {
            throw BufferAccessFailure.outOfRange(
                requested: subrange,
                available: scopedRange
            )
        }
        return try base.content(in: subrange)
    }

    @usableFromInline
    func unsafeCharacter(at location: Base.Location) -> Base.Content {
        return base.unsafeCharacter(at: location)
    }

    @usableFromInline
    func delete(in deletedRange: Base.Range) throws(BufferAccessFailure) {
        guard contains(range: deletedRange) else {
            throw BufferAccessFailure.outOfRange(
                requested: deletedRange,
                available: scopedRange
            )
        }
        guard deletedRange.length > 0 else { return }

        defer {
            self.scopedRange = Base.Range(
                location: self.scopedRange.location,
                length: max(0, self.scopedRange.length - deletedRange.length)
            )
        }

        try base.delete(in: deletedRange)
    }

    @usableFromInline
    func replace(range replacementRange: Base.Range, with content: Base.Content) throws(BufferAccessFailure) {
        guard contains(range: replacementRange) else {
            throw BufferAccessFailure.outOfRange(
                requested: replacementRange,
                available: scopedRange
            )
        }

        defer {
            let afterDelete = Base.Range(
                location: self.scopedRange.location,
                length: max(0, self.scopedRange.length - replacementRange.length)
            )
            self.scopedRange = Base.Range(
                location: afterDelete.location,
                length: max(0, afterDelete.length + content.length)
            )
        }

        try base.replace(range: replacementRange, with: content)
    }

    @usableFromInline
    func insert(_ content: Base.Content, at location: Base.Location) throws(BufferAccessFailure) {
        guard contains(range: .init(location: location, length: 0)) else {
            throw BufferAccessFailure.outOfRange(
                location: location,
                available: scopedRange
            )
        }

        defer {
            self.scopedRange = Base.Range(
                location: self.scopedRange.location,
                length: max(0, self.scopedRange.length + content.length)
            )
        }

        try base.insert(content, at: location)
    }

    @usableFromInline
    func modifying<T>(affectedRange: Base.Range, _ block: () -> T) throws(BufferAccessFailure) -> T {
        guard contains(range: affectedRange) else {
            throw BufferAccessFailure.outOfRange(
                requested: affectedRange,
                available: scopedRange
            )
        }

        return try base.modifying(affectedRange: affectedRange, block)
    }

    func modifyingScope<T>(_ block: () -> T) throws(BufferAccessFailure) -> T {
        return try base.modifying(affectedRange: scopedRange, block)
    }
}

extension ScopedBufferSlice: TextAnalysisCapable where Base: TextAnalysisCapable {
    @usableFromInline
    func wordRange(for searchRange: Base.Range) throws(BufferAccessFailure) -> Base.Range {
        guard contains(range: searchRange) else {
            throw BufferAccessFailure.outOfRange(
                requested: searchRange,
                available: scopedRange
            )
        }
        return try base.wordRange(for: searchRange)
    }

    @usableFromInline
    func lineRange(for searchRange: Base.Range) throws(BufferAccessFailure) -> Base.Range {
        guard contains(range: searchRange) else {
            throw BufferAccessFailure.outOfRange(
                requested: searchRange,
                available: scopedRange
            )
        }
        return try base.lineRange(for: searchRange)
    }
}

extension ScopedBufferSlice where Base: NSStringBuffer {
    @discardableResult
    @usableFromInline
    func evaluate(
        in range: NSRange,
        @ModificationBuilder _ expression: (AffectedRange) throws -> ModificationSequence
    ) throws -> ChangeInLength {
        return try expression(AffectedRange(range)).evaluate(in: self)
    }
}
