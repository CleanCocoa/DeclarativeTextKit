import Foundation
import TextBuffer

public struct AffectedRange {
    private final class Box {
        var value: NSRange

        init(_ value: NSRange) {
            self.value = value
        }
    }

    private let boxedValue: Box

    public internal(set) var value: NSRange {
        get { boxedValue.value }
        nonmutating set { boxedValue.value = newValue }
    }

    public var location: Int { value.location }
    public var endLocation: Int { value.endLocation }
    public var length: Int {
        get { value.length }
        nonmutating set { value.length = newValue }
    }

    public init(_ range: NSRange) {
        self.boxedValue = Box(range)
    }
}

extension AffectedRange {
    public init(
        location: Int,
        length: Int
    ) {
        self.init(NSRange(location: location, length: length))
    }
}

extension AffectedRange: CustomStringConvertible {
    public var description: String {
        "(\(value.location)..<\(value.endLocation))(len=\(value.length))"
    }
}
