import Foundation
import TextBuffer

public struct Line: Insertable {
    @inlinable
    static var `break`: String { String.newline }

    public let content: String

    public let insertFinalNewline: Bool = true

    public init() {
        self.init("")
    }

    public init(_ content: String) {
        self.content = content
    }

    public func insert(
        in buffer: any NSStringBuffer,
        at location: Int
    ) throws -> ChangeInLength {
        let newlineBefore = location > buffer.range.lowerBound
            ? buffer.lineBreak(at: location - 1)
            : true
        let newlineAfter = location < buffer.range.upperBound
            ? buffer.lineBreak(at: location)
            : !insertFinalNewline

        var changeInLength = ChangeInLength()

        if !newlineAfter {
            try buffer.insert(Line.break, at: location)
            changeInLength += ChangeInLength(Line.break)
        }

        changeInLength += try content.insert(in: buffer, at: location)

        if !newlineBefore {
            try buffer.insert(Line.break, at: location)
            changeInLength += ChangeInLength(Line.break)
        }

        return changeInLength
    }
}

// MARK: Half-Open Line

extension Line {
    public struct StartsWithNewlineIfNeeded: Insertable {
        public let content: String

        @usableFromInline
        internal init(_ content: String) {
            self.content = content
        }

        @inlinable
        public func insert(
            in buffer: any NSStringBuffer,
            at location: Int
        ) throws -> ChangeInLength {
            let newlineBefore = location > buffer.range.lowerBound
                ? buffer.lineBreak(at: location - 1)
                : true

            var changeInLength = ChangeInLength()

            changeInLength += try content.insert(in: buffer, at: location)

            if !newlineBefore {
                try buffer.insert(Line.break, at: location)
                changeInLength += ChangeInLength(Line.break)
            }

            return changeInLength
        }
    }

    public struct EndsWithNewlineIfNeeded: Insertable {
        public let content: String

        public let insertFinalNewline: Bool = true

        @usableFromInline
        internal init(_ content: String) {
            self.content = content
        }

        @inlinable
        public func insert(
            in buffer: any NSStringBuffer,
            at location: Int
        ) throws -> ChangeInLength {
            let newlineAfter = location < buffer.range.upperBound
                ? buffer.lineBreak(at: location)
                : !insertFinalNewline

            var changeInLength = ChangeInLength()

            if !newlineAfter {
                try buffer.insert(Line.break, at: location)
                changeInLength += ChangeInLength(Line.break)
            }

            changeInLength += try content.insert(in: buffer, at: location)

            return changeInLength
        }
    }
}

extension String {
    @usableFromInline
    static var newline: String { "\n" }
}

extension NSStringBuffer {
    @usableFromInline
    func lineBreak(at location: Int) -> Bool {
        return unsafeCharacter(at: location) == Line.break
    }
}
