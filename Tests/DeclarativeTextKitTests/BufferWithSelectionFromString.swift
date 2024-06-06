import DeclarativeTextKit

struct InvalidBufferStringRepresentation: Error {
    let stringRepresentation: String
    let parts: [String]
}

/// Create ``MutableStringBuffer`` from a string that matches the `debugDescription` format of either `"text {with selection}"` or `"text {^}insertion point"`.
/// - Throws: `InvalidBufferStringRepresentation` if `stringRepresentation` is malformed.
func buffer(_ stringRepresentation: String) throws -> MutableStringBuffer {
    /// Indices:
    /// - `0`: text before
    /// - `1`: text inside
    /// - `2`: text after
    let parts = stringRepresentation
        .split(separator: try Regex("[\\{\\}]"), omittingEmptySubsequences: false)
        .map { String($0) }

    switch parts.count {
    case 1:
        return MutableStringBuffer(stringRepresentation)

    case 3 where parts[1] == "^":
        let buffer = MutableStringBuffer(parts[0] + parts[2])
        buffer.selectedRange = .init(
            location: length(of: parts[0]),
            length: 0
        )
        return buffer

    case 3:
        let buffer = MutableStringBuffer(parts.joined(separator: ""))
        buffer.selectedRange = .init(
            location: length(of: parts[0]),
            length: length(of: parts[1])
        )
        return buffer

    default:
        throw InvalidBufferStringRepresentation(
            stringRepresentation: stringRepresentation,
            parts: parts
        )
    }
}
