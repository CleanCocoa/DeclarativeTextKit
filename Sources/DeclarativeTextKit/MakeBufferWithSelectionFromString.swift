#if DEBUG
public struct InvalidBufferStringRepresentation: Error {
    public let stringRepresentation: String
    public let parts: [String]
}

/// Test helper to create ``MutableStringBuffer`` from a string that matches the `debugDescription` format of either `"text «with selection»"` or `"text ˇinsertion point"`.
/// - Throws: `InvalidBufferStringRepresentation` if `stringRepresentation` is malformed.
@available(macOS, introduced: 13.0, message: "macOS 13 required for Regex")
public func makeBuffer(_ stringRepresentation: String) throws -> MutableStringBuffer {
    let buffer = MutableStringBuffer("")
    try change(buffer: buffer, to: stringRepresentation)
    return buffer
}

/// Test helper to replace `buffer`'s content and selectin that matches the `debugDescription` format of either `"text «with selection»"` or `"text ˇinsertion point"`.
/// - Throws: `InvalidBufferStringRepresentation` if `stringRepresentation` is malformed, `BufferAccessFailure` when changing `buffer` doesn't work.
@available(macOS, introduced: 13.0, message: "macOS 13 required for Regex")
public func change(
    buffer: any Buffer,
    to stringRepresentation: String
) throws {
    /// Indices:
    /// - `0`: text before
    /// - `1`: text inside
    /// - `2`: text after
    let selectionParts = stringRepresentation
        .split(separator: try Regex("[«»]"), omittingEmptySubsequences: false)
        .map { String($0) }

    if selectionParts.count == 3 {
        try buffer.replace(range: buffer.range, with: selectionParts.joined(separator: ""))
        buffer.selectedRange = .init(
            location: length(of: selectionParts[0]),
            length: length(of: selectionParts[1])
        )
        return
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
    try buffer.replace(range: buffer.range, with: insertionPointParts.joined(separator: ""))
    if stringRepresentation.contains("ˇ") {
        buffer.selectedRange = .init(
            location: length(of: insertionPointParts[0]),
            length: 0
        )
    } else {
        // `replace(range:with:)` moves the insertion point to the end; reset to the beginning so the result is similar to `MutableStringBuffer.init`.
        buffer.insertionLocation = 0
    }
}
#endif
