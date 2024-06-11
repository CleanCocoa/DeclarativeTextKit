#if DEBUG
public struct InvalidBufferStringRepresentation: Error {
    public let stringRepresentation: String
    public let parts: [String]
}

/// Create ``MutableStringBuffer`` from a string that matches the `debugDescription` format of either `"text «with selection»"` or `"text ˇinsertion point"`.
/// - Throws: `InvalidBufferStringRepresentation` if `stringRepresentation` is malformed.
@available(macOS, introduced: 13.0, message: "macOS 13 required for Regex")
public func makeBuffer(_ stringRepresentation: String) throws -> MutableStringBuffer {
    /// Indices:
    /// - `0`: text before
    /// - `1`: text inside
    /// - `2`: text after
    let selectionParts = stringRepresentation
        .split(separator: try Regex("[«»]"), omittingEmptySubsequences: false)
        .map { String($0) }

    if selectionParts.count == 3 {
        let buffer = MutableStringBuffer(selectionParts.joined(separator: ""))
        buffer.selectedRange = .init(
            location: length(of: selectionParts[0]),
            length: length(of: selectionParts[1])
        )
        return buffer
    } else if selectionParts.count > 1 {
        // Nested or half-open selection
        throw InvalidBufferStringRepresentation(
            stringRepresentation: stringRepresentation,
            parts: selectionParts
        )
    }

    let insertionPointParts = stringRepresentation
        .split(separator: "ˇ", maxSplits: 2, omittingEmptySubsequences: false)
        .map { String($0) }
    let buffer = MutableStringBuffer(insertionPointParts.joined(separator: ""))
    if stringRepresentation.contains("ˇ") {
        buffer.selectedRange = .init(
            location: length(of: insertionPointParts[0]),
            length: 0
        )
    }
    return buffer
}
#endif
