
//  Copyright © 2024 Christian Tietze. All rights reserved. Distributed under the MIT License.

/// Marking a ``Buffer/Range`` as to-be-modified in a range.
///
/// Depending on `Content`, you can use this to combine and group ``Modification``s at multiple locations into one block, or to execute multiple effects as a ``CommandSequence`` within a scope.
///
/// To surround the selected range in a Markdown text buffer with two asterisks, `**`, to make the selected text bold:
///
/// ```swift
/// Modifying(selectedRange) { modifiableRange in
///     Insert(modifiableRange.location) { "**" }
///     Insert(modifiableRange.endLocation) { "**" }
/// }
/// ```
///
/// To group multiple effects into one undo group:
///
/// ```swift
/// Modifying(buffer.range) { fullRange in
///     // This modification block updates `fullRange`
///     // to reflect the changes inside:
///     Modifying(fullRange) { editedRange in
///         Delete(
///             location: editedRange.location,
///             length: editedRange.length / 2
///         )
///     }
///
///     // Put insertion point at the end of the text
///     // as it looks after the previous modification:
///     Select(fullRange.endLocation)
/// }
/// ```
public struct Modifying<Content> {
    public typealias ModificationBody = (SelectedRange) -> Content

    let range: SelectedRange
    let modification: ModificationBody
}

extension Modifying: Modification, Expression
where Content: Modification {
    @_disfavoredOverload  // For client code, favor the throwing alternative available from the protocol extension.
    public func evaluate(in buffer: Buffer) -> Result<Content.Evaluation, BufferAccessFailure> {
        return _evaluate(in: buffer)
    }

    private func _evaluate<B: Buffer>(in buffer: B) -> Result<Content.Evaluation, BufferAccessFailure> {
        do {
            let scopedBuffer = try ScopedBufferSlice(base: buffer, scopedRange: range.value)

            return try scopedBuffer.modifyingScope {
                switch modification(range).evaluate(in: scopedBuffer) {
                case .success(var changeInLength):
                    range.consume(changeInLength: &changeInLength)
                    return .success(changeInLength)
                case .failure(let error):
                    return .failure(.wrap(error))
                }
            }
        } catch {
            return .failure(.wrap(error))
        }
    }

    public init(
        _ range: SelectedRange,
        @ModificationBuilder body: @escaping ModificationBody
    ) {
        self.range = range
        self.modification = body
    }

    @available(*, deprecated, message: "These initializers don't forward selection range changes properly a.t.m.; change make Modifying contingent on a StaticRange/dynamic SelectedRange")
    public init(
        _ range: Buffer.Range,
        @ModificationBuilder body: @escaping ModificationBody
    ) {
        self.init(SelectedRange(range), body: body)
    }

    @available(*, deprecated, message: "These initializers don't forward selection range changes properly a.t.m.; change make Modifying contingent on a StaticRange/dynamic SelectedRange")
    public init(
        location: Buffer.Location,
        length: Buffer.Length,
        @ModificationBuilder body: @escaping ModificationBody
    ) {
        self.init(Buffer.Range(location: location, length: length), body: body)
    }
}
